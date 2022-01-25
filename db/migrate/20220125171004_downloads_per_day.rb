class DownloadsPerDay < ActiveRecord::Migration[7.0]
  class Package < ActiveRecord::Base
  end

  def change
    add_column :packages, :downloads, :jsonb, null: false, default: {}

    today = Date.today - (Date.new(1970))

    reversible do |dir|
      dir.up do
        Package.where('download_count > 0').find_each do |p|
          p.downloads = { today => p.download_count}
          p.save!
        end
      end

      dir.down do
        Package.where.not(downloads: {}).find_each do |p|
          p.download_count = p.downloads.values.sum
          p.save!
        end
      end
    end

    remove_column :packages, :download_count, :integer, null: false, default: 0
  end
end
