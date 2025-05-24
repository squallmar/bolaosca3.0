class CreateRounds < ActiveRecord::Migration[8.0]
  def change
    create_table :rounds do |t|
      t.integer :number
      t.string :status, default: "pending"
      t.datetime :finalized_at

      t.timestamps
    end
  end
end
