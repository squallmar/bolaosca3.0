class AddNotesToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :notes, :text
  end
end
