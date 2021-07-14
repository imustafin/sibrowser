class AddTagsIndex < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE INDEX tags_icase_index ON packages USING gin((LOWER(tags::text)::jsonb))
    SQL
  end

  def down
    remove_index :packages, name: :tags_icase_index
  end
end
