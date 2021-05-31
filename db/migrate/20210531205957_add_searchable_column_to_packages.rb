class AddSearchableColumnToPackages < ActiveRecord::Migration[6.1]
  def up
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
  end




  def down
    remove_column :packages, :searchable
  end
end
