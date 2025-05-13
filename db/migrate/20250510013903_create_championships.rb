class CreateChampionships < ActiveRecord::Migration[8.0]
  def change
    create_table :championships do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
