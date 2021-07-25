class AddPredictedCategories < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :predicted_categories, :jsonb
  end
end
