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
  # As chaves são em inglês, e os valores são as strings que serão salvas no banco.
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

    # Itera sobre todas as partidas associadas a esta rodada.
    # Usamos `find_each` para lidar com grandes volumes de dados de forma eficiente.
    # Adicionamos `includes` para evitar N+1 queries ao acessar `score_a` e `score_b`.
    matches.includes(:team_a, :team_b).find_each do |match|
      # Verifica se a partida já está no status 'finalizado' (em português, do enum de Match)
      if match.finalizado? # Usa o método booleano do enum do Match
        puts "    [Match ##{match.id}] Já está finalizada. Ignorando."
        next # Pula para a próxima partida se já estiver finalizada
      end

      # Verifica se a partida tem placar preenchido antes de tentar finalizar.
      if match.score_a.present? && match.score_b.present?
        # Atualiza o status da partida para ':finalizado' (em português, do enum de Match)
        # e define a data de finalização.
        # Usamos `update!` para que uma exceção seja levantada se houver problemas de validação
        # no modelo Match ao tentar mudar o status.
        if match.update!(status: :finalizado, finalized_at: Time.current)
          puts "    [Match ##{match.id}] Finalizada com placar: #{match.score_a} - #{match.score_b}"
        else
          # Isso só seria alcançado se `update!` falhar sem levantar exceção (menos comum)
          Rails.logger.error "Erro ao finalizar partida ##{match.id}: #{match.errors.full_messages.join(', ')}"
          puts "    [Match ##{match.id}] ERRO: Não foi possível finalizar a partida. Verifique os logs."
        end
      else
        # Se não tem placar, registra um aviso.
        Rails.logger.warn "Partida ##{match.id} (Rodada #{self.number}) não tem placar e não foi finalizada automaticamente."
        puts "    [Match ##{match.id}] AVISO: Sem placar, não foi finalizada."
      end
    end
    puts "--- [Round ##{id}] Processamento de Partidas da Rodada Concluído ---"
  end
end