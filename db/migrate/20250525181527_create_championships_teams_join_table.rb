class CreateChampionshipsTeamsJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :championships, :teams do |t|
      t.index [:championship_id, :team_id], unique: true
      t.index [:team_id, :championship_id]
      
      t.timestamps
    end
  end
end