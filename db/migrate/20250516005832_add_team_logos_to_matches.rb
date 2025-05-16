class AddTeamLogosToMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :matches, :team_a_logo, :string
    add_column :matches, :team_b_logo, :string
  end
end
