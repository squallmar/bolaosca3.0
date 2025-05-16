class AddLocationToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :location, :string
  end
end
