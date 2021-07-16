class AddCategoriesToPackages < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION actual_categories(scores jsonb)
      RETURNS jsonb
      IMMUTABLE
      LANGUAGE sql
      AS $$
        WITH rr AS (SELECT * FROM jsonb_each(scores)),
          good AS (SELECT * FROM rr WHERE rr.value::float > 0.8 * (SELECT MAX(value::float) FROM rr))
        SELECT COALESCE(jsonb_object_agg(key, value), '{}') FROM good
      $$;
    SQL

    execute <<-SQL
      ALTER TABLE packages
      ADD COLUMN categories jsonb GENERATED ALWAYS AS (actual_categories(category_scores)) STORED;
    SQL

  end

  def down
    remove_column :packages, :categories
    execute <<-SQL
      DROP FUNCTION actual_categories;
    SQL
  end
end
