class AddPackageVkDownloadUrlUpdatedAt < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :vk_download_url_updated_at, :datetime

    up_only do
      execute 'update packages set vk_download_url_updated_at = updated_at'
    end
  end
end
