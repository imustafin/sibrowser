class AddImageInfo < ActiveRecord::Migration[7.0]
  def change
    change_table :packages do |t|
      t.integer :logo_width
      t.integer :logo_height
    end
  end
end
