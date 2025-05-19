class AddTotalPointsToUsers < ActiveRecord::Migration[8.0]
def change
    add_column :users, :total_points, :integer, default: 0
  end
end
