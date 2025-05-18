class AddTeamReferencesToMatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :matches, :team_a, foreign_key: { to_table: :teams }
    add_reference :matches, :team_b, foreign_key: { to_table: :teams }

    # Mantém os campos originais como fallback
    change_column_null :matches, :team_a, true
    change_column_null :matches, :team_b, true
  end
end
