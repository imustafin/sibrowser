class AddPackageCatMusicRatio < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :cat_music_ratio, :float, null: false, default: 0

    add_index :packages, :cat_music_ratio
  end
end
