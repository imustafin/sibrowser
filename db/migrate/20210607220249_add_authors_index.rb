class AddAuthorsIndex < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE INDEX authors_icase_index ON packages USING gin((LOWER(authors::text)::jsonb))
    SQL
  end

  def down
    remove_index :packages, name: :authors_icase_index
  end
end
