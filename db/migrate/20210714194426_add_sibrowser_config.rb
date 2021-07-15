class AddSibrowserConfig < ActiveRecord::Migration[6.1]
  def change
    create_table :sibrowser_configs do |t|
      t.jsonb :tags_to_cats
    end
  end
end
