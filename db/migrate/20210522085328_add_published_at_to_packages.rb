class AddPublishedAtToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :published_at, :datetime
  end
end
