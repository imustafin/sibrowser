class PackageSerializedToJsonb < ActiveRecord::Migration[6.1]
  def change
    remove_column :packages, :authors, type: :string
    add_column :packages, :authors, :jsonb

    remove_column :packages, :structure, type: :text
    add_column :packages, :structure, :jsonb

    remove_column :packages, :tags, type: :text
    add_column :packages, :tags, :jsonb
  end
end
