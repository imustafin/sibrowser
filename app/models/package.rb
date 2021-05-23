class Package < ApplicationRecord
  validates :name, presence: true
  validates :source_link, presence: true

  serialize :authors, Array
  serialize :structure, Hash
  serialize :tags, Array
end
