class CreateBets < ActiveRecord::Migration[8.0]
  def change
    create_table :bets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.integer :guess_a
      t.integer :guess_b
      t.integer :points

      t.timestamps
    end
  end
end
