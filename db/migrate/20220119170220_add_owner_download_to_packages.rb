class AddOwnerDownloadToPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :vk_owner_id, :string
    add_column :packages, :vk_download_url, :string
  end
end
