class AddSupersededIdsToPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :superseded_ids, :bigint, array: true, null: false, default: []

    add_index :packages, :superseded_ids, using: :gin
  end
end
