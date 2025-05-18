class ChangeStatusToIntegerInBets < ActiveRecord::Migration[8.0]
  def up
    status_map = {
      'pending' => 0,
      'confirmed' => 1,
      'canceled' => 2
    }

    add_column :bets, :status_tmp, :integer

    Bet.reset_column_information
    Bet.find_each do |bet|
      bet.update_column(:status_tmp, status_map[bet.status])
    end

    remove_column :bets, :status
    rename_column :bets, :status_tmp, :status
  

  def down
    status_map = {
      0 => 'pending',
      1 => 'confirmed',
      2 => 'canceled'
    }

    add_column :bets, :status_tmp, :string

    Bet.reset_column_information
    Bet.find_each do |bet|
      bet.update_column(:status_tmp, status_map[bet.status])
    end

    remove_column :bets, :status
    rename_column :bets, :status_tmp, :status
  end
end
