class AddLogoBytesToPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :logo_bytes, :bytea
  end
end
