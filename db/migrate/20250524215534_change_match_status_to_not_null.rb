class ChangeMatchStatusToNotNull < ActiveRecord::Migration[8.0]
def change
    # Primeiro, atualiza quaisquer valores NULL existentes para o default 'agendado'
    Match.where(status: nil).update_all(status: Match.statuses[:agendado])

    # Em seguida, altera a coluna para NOT NULL com um default
    change_column_null :matches, :status, false, Match.statuses[:agendado]
    change_column_default :matches, :status, Match.statuses[:agendado]
  end
end