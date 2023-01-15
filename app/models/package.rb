class Package < ApplicationRecord
  include PgSearch::Model

  # Load download_count
  after_save :reload

  # CHANGELOG
  #
  # 9
  # * Add package file hash
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
  VERSION = 9

  validates :name, presence: true
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

  def self.question_types(q)
    q['question_types']
      .take_while { |t| t != 'marker' }
      .map { |x| x == 'say' ? 'text' : x }
      .uniq
      .map(&:to_sym)
  end

  def self.question_distribution(col)
    col = col.flat_map { |r| r['themes'] } if col.first&.key?('themes')
    col = col.flat_map { |r| r['questions'] } if col.first&.key?('questions')

    types = SibrowserConfig::QUESTION_TYPES.to_h { |k| [k, 0] }

    col.each do |q|
      question_types(q).each { |t| types[t] += 1 }
    end

    total = col.count

    types.transform_values! { |v| v.fdiv(total)  }

    { total:, types: }
  end

  def similar
    dist = self.class.sanitize_sql(['cat_cube <-> ?', cat_cube])

    Package
      .where.not(id:)
      .select("#{dist} as distance", '*')
      .order(Arel.sql(dist) => :asc)
  end

  def question_distribution
    return nil unless structure

    self.class.question_distribution(structure)
  end

  def self.update_or_create!(params)
    transaction do
      model = find_by(file_hash: params[:file_hash])

      params = params.merge(version: VERSION)

      unless model
        create!(params)
      else
        params[:published_at] = [
          model.published_at,
          params[:published_at].to_datetime
        ].min
        model.update(params)
        model.save!
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

  def categories(all = false)
    cats = (read_attribute(:categories)&.dup || {})

    # Delete old CATEGORIES replaced by CATEGORIES_2
    cats.delete('anime')
    cats.delete('gam')
    cats.delete('mus')
    cats.delete('fic')
    cats.delete('hum')
    cats.delete('meme')

    SibrowserConfig::CATEGORIES_2.map(&:to_sym).each do |c|
      if all || self["cat_#{c}_ratio"] >= CATEGORY_2_MIN
        cats[c] = self["cat_#{c}_ratio"]
      end
    end

    cats.sort_by(&:last).reverse.to_h
  end

  scope :by_author, ->(author) { where('LOWER(authors::text)::jsonb @> to_jsonb(LOWER(?)::text)', author) }

  scope :by_tag, ->(tag) { where('LOWER(tags::text)::jsonb @> to_jsonb(LOWER(?)::text)', tag) }

  CATEGORY_2_MIN = 0.5

  scope :by_category, ->(cat) {
    if SibrowserConfig::CATEGORIES_2.include?(cat)
      where("cat_#{cat}_ratio >= ?", CATEGORY_2_MIN)
    else
      where("(categories->>?) IS NOT NULL", cat)
    end
  }

  scope :order_by_category, ->(cat) {
    if SibrowserConfig::CATEGORIES_2.include?(cat)
      order("cat_#{cat}_ratio" => :desc)
    else SibrowserConfig::CATEGORIES.include?(cat)
      order(Arel.sql("categories->>'#{cat}' DESC"))
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

  def supersede!(p)
    with_lock do
      superseded_ids << p.id

      p.downloads.each do |k, v|
        downloads[k] ||= 0
        downloads[k] += v
      end

      self.posts = (posts + p.posts).uniq { |x| x['link'] }

      p.destroy!
      save!
    end
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

  def earliest_post
    posts.min_by { |x| x['published_at'].to_datetime }
  end
end
