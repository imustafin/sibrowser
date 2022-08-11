class AddStructureClassificationToPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :structure_classification, :jsonb
  end
end
