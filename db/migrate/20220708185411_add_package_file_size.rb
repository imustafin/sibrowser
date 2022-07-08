class AddPackageFileSize < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :file_size, :bigint
  end
end
