class AddDisappearedAt < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :disappeared_at, :datetime
    add_index :packages, :disappeared_at
  end
end
