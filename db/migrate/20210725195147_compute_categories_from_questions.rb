class ComputeCategoriesFromQuestions < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION actual_categories(scores jsonb)
      RETURNS jsonb
      IMMUTABLE
      LANGUAGE sql
      AS $$
        WITH cats AS (
          SELECT
            jsonb_array_elements_text(jsonb_path_query_array(scores, '$.*.*.*')) AS cat
        ),
        with_counts AS (SELECT cat, COUNT(*) FROM cats GROUP BY cat ORDER BY COUNT(*) DESC),
        with_ratios AS (
          SELECT cat,
                count / GREATEST((SELECT SUM(count) FROM with_counts), 1) AS ratio
          FROM with_counts
        )

        SELECT jsonb_object_agg(cat, ratio) FROM with_ratios
          WHERE (ratio > 0.8 * (SELECT MAX(ratio) FROM with_ratios))
      $$;
    SQL

    remove_column :packages, :categories

    execute <<-SQL
      ALTER TABLE packages
      ADD COLUMN categories jsonb GENERATED ALWAYS AS (actual_categories(predicted_categories)) STORED;
    SQL
  end

  def down
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

    remove_column :packages, :categories

    execute <<-SQL
      ALTER TABLE packages
      ADD COLUMN categories jsonb GENERATED ALWAYS AS (actual_categories(category_scores)) STORED;
    SQL
  end
end
