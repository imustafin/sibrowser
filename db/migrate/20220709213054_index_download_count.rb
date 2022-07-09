class IndexDownloadCount < ActiveRecord::Migration[7.0]

  def add_func
    reversible do |dir|
      dir.up { execute <<~SQL }
        CREATE FUNCTION sum_integer_values(obj jsonb) RETURNS integer
        LANGUAGE sql IMMUTABLE
        AS $_$
          SELECT COALESCE(sum(sub.item), 0) FROM (
            SELECT jsonb_path_query(obj, '$.*')::integer AS item
          ) sub
        $_$;
      SQL

      dir.down { execute 'DROP FUNCTION sum_integer_values' }
    end
  end

  def change
    add_func

    add_column :packages, :download_count, :virtual,
      type: :integer,
      as: 'sum_integer_values(downloads)',
      stored: true

    add_index :packages, :download_count
  end
end
