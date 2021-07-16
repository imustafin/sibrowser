class AddManualCategories < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :manual_categories, :jsonb
  end
end
