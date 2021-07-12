class AddRoundNamesToPackageSearchable < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    remove_column :packages, :searchable

    execute <<-SQL
      ALTER TABLE packages
      ADD COLUMN searchable tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('russian', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('russian', coalesce(filename, '')), 'A') ||
        setweight(to_tsvector('russian', coalesce(authors, '{}')), 'B') ||
        setweight(to_tsvector('russian', coalesce(tags, '{}')), 'B') ||

        -- Round names
        setweight(to_tsvector('russian', coalesce(jsonb_path_query_array(structure, '$[*].name'), '{}')), 'B') ||
        -- Theme names
        setweight(to_tsvector('russian', coalesce(jsonb_path_query_array(structure, '$[*].themes[*].name'), '{}')), 'B') ||

        setweight(to_tsvector('russian', coalesce(post_text, '')), 'C')
      ) STORED;
    SQL

    add_index :packages, :searchable, using: :gin, algorithm: :concurrently
  end

  def down
    remove_column :packages, :searchable

    execute <<-SQL
      ALTER TABLE packages
      ADD COLUMN searchable tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('russian', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('russian', coalesce(filename, '')), 'A') ||
        setweight(to_tsvector('russian', coalesce(authors, '{}')), 'B') ||
        setweight(to_tsvector('russian', coalesce(tags, '{}')), 'B') ||
        setweight(to_tsvector('russian', coalesce(jsonb_path_query_array(structure, '$[*].name'), '{}')), 'B') ||
        setweight(to_tsvector('russian', coalesce(post_text, '')), 'C')
      ) STORED;
    SQL

    add_index :packages, :searchable, using: :gin, algorithm: :concurrently
  end
end
