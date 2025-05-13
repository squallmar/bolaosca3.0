class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.references :championship, null: false, foreign_key: true
      t.string :team_a
      t.string :team_b
      t.integer :score_a
      t.integer :score_b
      t.datetime :match_date
      t.string :status

      t.timestamps
    end
  end
end
