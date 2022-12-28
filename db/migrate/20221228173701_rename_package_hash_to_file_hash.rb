class RenamePackageHashToFileHash < ActiveRecord::Migration[7.0]
  def change
    rename_column :packages, :hash, :file_hash
  end
end
