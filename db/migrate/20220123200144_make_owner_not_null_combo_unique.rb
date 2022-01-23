class MakeOwnerNotNullComboUnique < ActiveRecord::Migration[7.0]
  def change
    change_column_null :packages, :vk_owner_id, false
    remove_index :packages, :vk_document_id
    add_index :packages, [:vk_document_id, :vk_owner_id], unique: true
  end
end
