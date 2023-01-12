class AddSocialCat < ActiveRecord::Migration[7.0]
  def change
    change_table :packages do |t|
      t.float :cat_social_ratio, null: false, default: 0

      t.remove :cat_cube
      t.virtual :cat_cube, type: :cube, stored: true, as: <<~SQL
        cube(array[
          cat_anime_ratio,
          cat_videogames_ratio,
          cat_music_ratio,
          cat_movies_ratio,
          cat_social_ratio
        ])
      SQL
    end

    add_index :packages, :cat_social_ratio
    add_index :packages, :cat_cube, using: :gist
  end
end
