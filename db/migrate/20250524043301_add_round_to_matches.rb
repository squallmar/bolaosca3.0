class AddRoundToMatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :matches, :round, null: true, foreign_key: true
  end
end
