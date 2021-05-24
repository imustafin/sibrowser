class AddFileIdsToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :vk_document_id, :string, unique: true, null: false

    add_index :packages, :vk_document_id
  end
end
