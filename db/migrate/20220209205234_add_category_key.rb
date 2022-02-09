class AddCategoryKey < ActiveRecord::Migration[7.0]
  def change
    add_column :packages, :category_text, :text
    add_column :packages, :category_ts, :virtual,
      type: :tsvector,
      as: "to_tsvector('russian', category_text)",
      stored: true
  end
end
