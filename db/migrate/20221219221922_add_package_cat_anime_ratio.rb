class AddPackageCatAnimeRatio < ActiveRecord::Migration[7.0]
  def change
    change_table :packages do |t|
      t.float :cat_anime_ratio, null: false, default: 0
    end
  end
end
