class AddSiqColumnToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :filename, :string
  end
end
