# app/models/round.rb
class Round < ApplicationRecord
  # Associações
  # Uma rodada pode ter muitas partidas.
  # `dependent: :nullify` significa que se uma rodada for deletada,
  # o `round_id` nas partidas associadas será definido como NULL,
  # em vez de deletar as partidas. Isso é geralmente mais seguro.
  has_many :matches, dependent: :nullify

  # Validações
  validates :number, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }

  # Enum para o status da rodada
  # Define os possíveis status e o valor padrão para 'pending'.
  enum :status, { pending: 'pending', finalized: 'finalized' }, default: :pending

  # Callbacks
  # `after_update_commit` garante que o banco de dados já foi atualizado
  # antes de tentar finalizar as partidas.
  # `if: :finalized?` garante que este callback só roda se o status da rodada mudou para 'finalized'.
  after_update_commit :finalize_matches_in_round, if: :finalized?

  # Método de instância para finalizar uma rodada
  # Este método será chamado pelo controller `Admin::RoundsController`
  def finalize!
    # Atualiza o status da rodada para 'finalized' e registra a data/hora da finalização.
    # `update!` levanta uma exceção se a validação falhar (o que é bom para depuração).
    update!(status: :finalized, finalized_at: Time.current)
  end

  # Lógica para finalizar todas as partidas associadas a esta rodada
  def finalize_matches_in_round
    puts "--- [Round ##{id}] Finalizando partidas da rodada #{number} ---"
    # Itera sobre as partidas desta rodada que ainda não estão finalizadas.
    # Isso evita reprocessar partidas já finalizadas.
    matches.where.not(status: :finalized).each do |match|
      # Verifica se a partida tem placar preenchido antes de finalizar.
      # Se não tiver, decide o que fazer:
      if match.score_a.present? && match.score_b.present?
        # Se tem placar, finalize-a. O `after_update_commit` da Match será acionado.
        match.update(status: :finalized, finalized_at: Time.current)
        puts "    [Match ##{match.id}] Finalizada com placar: #{match.score_a} - #{match.score_b}"
      else
        # Se não tem placar, você pode decidir:
        # 1. Avisar que a partida não foi finalizada por falta de placar (current behavior)
        Rails.logger.warn "Partida ##{match.id} (Rodada #{self.number}) não tem placar e não foi finalizada automaticamente."
        # 2. Forçar a finalização com 0-0 e avisar (descomente a linha abaixo e comente a de cima se preferir)
        # match.update(score_a: 0, score_b: 0, status: :finalized, finalized_at: Time.current)
        # puts "    [Match ##{match.id}] Finalizada com placar 0 - 0 (originalmente sem placar)."
      end
    end
    puts "--- [Round ##{id}] Processamento de Partidas da Rodada Concluído ---"
  end
end