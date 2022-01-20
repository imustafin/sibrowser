class AddDownloadCountToPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :download_count, :integer, null: false, default: 0
  end
end
