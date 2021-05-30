class AddVersionToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :version, :integer
    change_column_null :packages, :version, false, 0
  end
end
