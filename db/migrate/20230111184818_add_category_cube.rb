class AddCategoryCube < ActiveRecord::Migration[7.0]
  def change
    enable_extension :cube

    add_column :packages, :cat_cube, :cube,
      stored: true,
      as: <<~SQL
        cube(array[
          cat_anime_ratio,
          cat_videogames_ratio,
          cat_music_ratio,
          cat_movies_ratio
        ])
      SQL

    add_index :packages, :cat_cube, using: :gist
  end
end
