class AddPackageHash < ActiveRecord::Migration[7.0]
  def change
    change_table :packages do |t|
      t.binary :hash

      t.check_constraint 'version < 9 or disappeared_at is null or hash is not null'
    end
  end
end
