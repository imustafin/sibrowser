class AddPostTextToPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :packages, :post_text, :text
  end
end
