class AddIndexToPackages < ActiveRecord::Migration[6.1]
  def change
    remove_index :packages, name: :index_packages_on_vk_document_id
    add_index :packages, :vk_document_id, unique: true
  end
end
