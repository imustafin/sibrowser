class AddPackageCatMoviesRatio < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :cat_movies_ratio, :float, null: false, default: 0

    add_index :packages, :cat_movies_ratio
  end
end
