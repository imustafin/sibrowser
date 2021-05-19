class CreatePackages < ActiveRecord::Migration[6.1]
  def change
    create_table :packages do |t|
      t.string :name, null: false
      t.string :authors
      t.string :source_link, null: false

      t.timestamps
    end
  end
end
