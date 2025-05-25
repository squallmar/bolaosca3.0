class AddActiveToChampionships < ActiveRecord::Migration[8.0]
  def change
    add_column :championships, :active, :boolean
  end
end
