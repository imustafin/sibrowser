class AddCategoryScoresToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :category_scores, :jsonb
  end
end
