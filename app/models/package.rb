class Package < ApplicationRecord
  include PgSearch::Model

  # Load download_count
  after_save :reload

  # CHANGELOG
  #
  # 8
  # * Zip file names can be unencoded, some chars are never encoded
  #
  # 7
  # * Add webp image, width, height
  #
  # 6
  # * Add file_size
  #
  # 5
  # * Add vk_owner_id
  #   VK identifies docs by (vk_owner_id, vk_document_id),
  #   so search by the whole pair
  # * Add vk_download_url
  VERSION = 8

  validates :name, presence: true
  validates :source_link, presence: true
  validates :vk_document_id, presence: true
  validates :vk_owner_id, presence: true
  validates :version, presence: true

  pg_search_scope :search_freetext,
    against: :searchable, # actually not used if tsvector_column is specified
    using: {
      tsearch: {
        dictionary: 'russian',
        tsvector_column: 'searchable'
      }
    }

  def authors
    (self[:authors] || []).reject(&:blank?)
  end

  SOURCE_LINK_LIFESPAN = 24.hours

  def touch_vk_download_url
    self.vk_download_url_updated_at = Time.now
  end

  def vk_download_url_fresh?
    (Time.now - vk_download_url_updated_at) < SOURCE_LINK_LIFESPAN
  end

  def self.question_type(q)
    ts = q['question_types'].take_while { |t| t != 'marker' }

    ts.delete('say')
    ts.delete('text')
    ts.uniq!

    if ts.empty?
      :text
    elsif ts.count == 1
      ts.first.to_sym
    else
      :mixed
    end
  end

  def self.question_distribution(col)
    col = col.flat_map { |r| r['themes'] } if col.first&.key?('themes')
    col = col.flat_map { |r| r['questions'] } if col.first&.key?('questions')

    types = col.map { |q| question_type(q) }

    {
      total: col.count,
      types: types.tally.sort_by { |x| -x.last }.to_h
    }
  end

  def question_distribution
    return nil unless structure

    self.class.question_distribution(structure)
  end

  def self.update_or_create!(params)
    transaction do
      model = find_by(
        vk_document_id: params[:vk_document_id],
        vk_owner_id: params[:vk_owner_id]
      )

      params = params.merge(version: VERSION)

      unless model
        create!(params)
      else
        # Same logic as in .skip_updating?
        if params[:published_at] < model.published_at \
            || model.version < VERSION \
            || model.structure.blank? \
            || model.disappeared_at
          model.update(params)
          model.save!
        end
      end
    end
  end

  # Skip updating if there is a record
  # which was published not after this new date and has compatible version
  def self.skip_updating?(new_vk_document_id, new_vk_owner_id, new_published_at)
    where(vk_document_id: new_vk_document_id, vk_owner_id: new_vk_owner_id)
      .where('published_at <= ?', new_published_at) # The older post can have a more relevant original_text
      .where('version >= ?', VERSION) # same version is compatible, greater version should not happen
      .where('structure IS NOT NULL') # parse if structure was deleted when upgrading
      .where(disappeared_at: nil) # good version should be present
      .exists?
  end

  scope :by_author, ->(author) { where('LOWER(authors::text)::jsonb @> to_jsonb(LOWER(?)::text)', author) }

  scope :by_tag, ->(tag) { where('LOWER(tags::text)::jsonb @> to_jsonb(LOWER(?)::text)', tag) }

  scope :by_category, ->(cat) { where("(categories->>?) IS NOT NULL", cat)}

  scope :reorder_by_category, ->(cat) {
    if SibrowserConfig::CATEGORIES.include?(cat)
      reorder(Arel.sql("categories->>'#{cat}' DESC"))
    else
      self
    end
  }

  scope :visible, -> { where(disappeared_at: nil) }

  scope :visible_paged, ->(page) {
    visible
      .order(published_at: :desc, id: :desc)
      .page(page)
      .per(5)
  }

  scope :superseders, ->(id) { where("superseded_ids @> ARRAY[?]::bigint[]", [id]) }

  def supersede(p)
    superseded_ids << p.id
    p.destroy!
  end

  def add_download
    k = self.class.date_to_download_key(Date.today)
    downloads[k] ||= 0
    downloads[k] += 1
  end

  def self.date_to_download_key(d)
    (d - Date.new(1970)).to_i.to_s
  end

  def self.download_stats
    d = Date.today
    binds = {
      day: date_to_download_key(d),
      week: date_to_download_key(d.beginning_of_week),
      month: date_to_download_key(d.beginning_of_month),
      year: date_to_download_key(d.beginning_of_year),
      total: nil
    }

    j = Arel::Table.new(:j)

    selects = binds.map do |k, v|
      arel_cast(j[:value], :integer)
        .sum
        .then { |s| v ? s.filter(arel_cast(j[:key], :integer).gteq(v)) : s }
        .then { |s| s.coalesce(s, 0) }
        .as(k.to_s)
    end

    all
      .from("#{table_name}, jsonb_each(downloads) j")
      .select(*selects)
      .as_json
      .first
      .to_h
      .symbolize_keys
      .except(:id)
  end

  scope :download_counts, -> {
    date_expr = Arel.sql("DATE '1970-01-01' + j.key::integer")

    Package
      .select('date, SUM(count) AS count')
      .from(
        from('packages, jsonb_each(downloads) j')
        .select("#{date_expr} AS date, COALESCE(j.value::integer, 0) AS count")
      )
      .group(:date)
  }

  ONLINE_LIMIT = 100.megabytes

  def too_big_for_online?
    file_size && file_size > ONLINE_LIMIT
  end

  def has_logo?
    logo_bytes != nil
  end
end
