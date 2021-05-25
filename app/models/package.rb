class Package < ApplicationRecord
  validates :name, presence: true
  validates :source_link, presence: true
  validates :vk_document_id, presence: true, uniqueness: true

  serialize :authors, Array
  serialize :structure, Hash
  serialize :tags, Array

  def self.update_or_create!(params)
    retries = 0

    begin
      transaction do
        model = find_by(vk_document_id: params[:vk_document_id])

        unless model
          create!(params)
        else
          # Update if params is older (maybe a more specific original post)
          if params[:published_at] <= model.published_at
            model.update(params)
            model.save!
          end
        end
      end
    rescue e
      raise e if retries > 2

      retries += 1
      retry
    end
  end

  def self.skip_updating?(new_vk_document_id, new_published_at)
    where(vk_document_id: new_vk_document_id)
      .where('published_at < ?', new_published_at)
      .exists?
  end
end
