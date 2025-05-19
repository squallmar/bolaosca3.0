class AddFinalizedAtToMatches < ActiveRecord::Migration[8.0]

  def change

    add_column :matches, :finalized_at, :datetime

  end

end

