class AddPackagePosts < ActiveRecord::Migration[7.0]
  def change
    change_table :packages do |t|
      t.jsonb :posts, default: [], null: false
      t.datetime :parsed_at
    end

    change_column_null :packages, :parsed_at, false, Time.current

    execute <<~SQL
      update packages set posts = json_build_array(
        json_build_object(
          'link', source_link,
          'text', post_text,
          'document_id', vk_document_id::integer,
          'owner_id', vk_owner_id::integer,
          'published_at', published_at,
          'filename', filename
        )
      )
    SQL

    change_table :packages do |t|
      t.remove :searchable
      t.remove :source_link
      t.remove :post_text
      t.remove :vk_document_id
      t.remove :vk_owner_id
      t.remove :filename
    end

    execute <<~SQL
      alter table packages
      add column searchable tsvector generated always as (
        setweight(to_tsvector('russian', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('russian', coalesce(authors, '{}')), 'B') ||
        setweight(to_tsvector('russian', coalesce(tags, '{}')), 'B') ||
        setweight(to_tsvector('russian', coalesce(
          jsonb_path_query_array(structure, '$[*]."name"'),
          '{}'
        )), 'B') ||
        setweight(to_tsvector('russian', coalesce(
          jsonb_path_query_array(structure, '$[*]."themes"[*]."name"'),
          '{}'
        )), 'B') ||
        setweight(to_tsvector('russian', coalesce(
          jsonb_path_query_array(posts, '$[*]."text"'),
          '{}'
        )), 'C')
      ) stored
    SQL

    add_index :packages, :searchable, using: :gin
  end
end
