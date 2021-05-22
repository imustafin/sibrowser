class AddStructureToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :structure, :text
  end
end
