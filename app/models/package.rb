class Package < ApplicationRecord
  validates :name, presence: true
  validates :source_link, presence: true
end
