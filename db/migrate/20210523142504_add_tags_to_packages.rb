class AddTagsToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :tags, :string
  end
end
