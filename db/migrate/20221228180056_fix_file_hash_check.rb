class FixFileHashCheck < ActiveRecord::Migration[7.0]
  def change
    change_table :packages do |t|
      t.remove_check_constraint(
        expression: 'version < 9 or disappeared_at is null or hash is not null'
      )

      t.check_constraint(
        'version < 9 or disappeared_at is not null or file_hash is not null',
        name: 'file_hash_since_version_9'
      )
    end
  end
end
