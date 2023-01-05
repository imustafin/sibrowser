class AddVideogamesRatio < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :cat_videogames_ratio, :float, null: false, default: 0
  end
end
