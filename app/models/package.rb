class Package < ApplicationRecord
  include PgSearch::Model

  VERSION = 2

  validates :name, presence: true
  validates :source_link, presence: true
  validates :vk_document_id, presence: true, uniqueness: true
  validates :version, presence: true

  pg_search_scope :search_freetext,
    against: :searchable, # actually not used if tsvector_column is specified
    using: {
      tsearch: {
        dictionary: 'russian',
        tsvector_column: 'searchable'
      }
    }

  def question_distribution
    return nil unless structure

    questions = structure
      .flat_map { |r| r['themes'] }
      .flat_map { |t| t['questions'] }

    types = questions.map do |q|
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

    {
      total: questions.count,
      types: types.tally.sort_by { |x| -x.last }.to_h
    }
  end

  def self.update_or_create!(params)
    transaction do
      model = find_by(vk_document_id: params[:vk_document_id])

      params = params.merge(version: VERSION)

      unless model
        create!(params)
      else
        # Same login as in .skip_updating?
        if params[:published_at] < model.published_at || model.version < VERSION
          model.update(params)
          model.save!
        end
      end
    end
  end

  # Skip updating if there is a record
  # which was published not after this new date and has compatible version
  def self.skip_updating?(new_vk_document_id, new_published_at)
    where(vk_document_id: new_vk_document_id)
      .where('published_at <= ?', new_published_at) # The older post can have a more relevant original_text
      .where('version >= ?', VERSION) # same version is compatible, greater version should not happen
      .exists?
  end
end
