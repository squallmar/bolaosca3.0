# app/models/match.rb
class Match < ApplicationRecord
  has_many :bets, dependent: :destroy
  belongs_to :championship
  belongs_to :team_a, class_name: "Team", optional: true
  belongs_to :team_b, class_name: "Team", optional: true
  has_one_attached :team_a_logo
  has_one_attached :team_b_logo
  belongs_to :round, optional: true # Correto!

  enum :status, {agendado: 0, em_andamento: 1, finalizado: 2, cancelado: 3}, default: :agendado

  validates :team_a_id, :team_b_id, presence: true
  validates :team_a_id, uniqueness: { scope: [ :team_b_id, :match_date ], message: "já existe uma partida agendada com esses times na mesma data" }
  validates :team_b_id, uniqueness: { scope: [ :team_a_id, :match_date ], message: "já existe uma partida agendada com esses times na mesma data" }
  validates :team_a, :team_b, :match_date, presence: true
  validates :championship, presence: true

  validate :future_match_date
  validate :validate_logo_files

  scope :upcoming, -> { where("match_date >= ?", Time.current).order(match_date: :asc) }
  scope :past, -> { where("match_date <= ?", Time.current).order(match_date: :desc) }
  scope :with_championship, ->(limit = 5) { includes(:championship).limit(limit) }

  # --- AJUSTE AQUI ---
  # Removemos `after_update :update_rankings`
  # Usaremos APENAS `after_update_commit :calculate_points_for_bets`
  # Ele será acionado quando o status MUDAR para :finalizado.
  after_update_commit :calculate_points_for_bets, if: -> { saved_change_to_status? && finalizado? }


  # O método `can_be_finalized?` ainda é útil para lógica de exibição, mas não será mais usado
  # para disparar a finalização diretamente do MatchResultsController.
  def can_be_finalized?
    !finalizado? &&
      match_date.present? &&
      match_date <= Time.current &&
      team_a.present? &&
      team_b.present?
  end

  # O método `finalize!` dentro do modelo Match não será mais chamado diretamente pelo
  # `MatchResultsController` (que agora só salva placares) nem pelo `RoundsController`
  # (que apenas define o status como `finalizado`).
  # Você pode removê-lo se não houver outros locais que o usem, ou mantê-lo se quiser.
  # Para o fluxo atual, ele é redundante.
  # def finalize!(home_score, away_score)
  #   update(
  #     score_a: home_score,
  #     score_b: away_score,
  #     status: :finalizado,
  #     finalized_at: Time.current
  #   )
  # end

  # Métodos para compatibilidade
  def team_a_name
    team_a&.name || "Time A"
  end

  def team_b_name
    team_b&.name || "Time B"
  end

  def team_a_logo_or_default
    team_a&.logo || team_a_logo || "default_team.png"
  end

  def team_b_logo_or_default
    team_b&.logo || team_b_logo || "default_team.png"
  end

  private

  # Renomeei de `update_rankings` para `calculate_points_for_bets` e consolidei a lógica.
  # Esta lógica será chamada APENAS quando o status da partida for alterado para 'finalizado'.
  def calculate_points_for_bets
    # Só calcula se a partida tem placares válidos e está finalizada
    if finalizado? && score_a.present? && score_b.present?
      puts "\n--- [Match ##{id}] Processando Pontos para apostas (STATUS FINALIZADO) ---"
      puts "Placar da Partida: #{self.score_a} x #{self.score_b}"

      bets.includes(:user).find_each do |bet|
        puts "    [Bet ##{bet.id}] Processando Aposta do Usuário #{bet.user&.email || 'Desconhecido'} (Palpite: #{bet.guess_a} x #{bet.guess_b})"

        points = calculate_single_bet_points(bet) # Renomeado para clareza
        puts "    Pontos calculados para aposta #{bet.id}: #{points}"

        # Se os pontos calculados são diferentes dos pontos salvos, atualiza.
        # bet.update_column evita callbacks e validações do Bet, ideal para bulk updates.
        if bet.points != points
          puts "    Atualizando pontos da aposta #{bet.id} de #{bet.points} para #{points}"
          bet.update_column(:points, points)
        else
          puts "    Pontos da aposta #{bet.id} já são #{points}. Nenhuma atualização necessária."
        end

        # Chama o método no User para atualizar o total de pontos
        # Assumindo que `user.update_total_points` recalcula o total somando as apostas do user.
        bet.user&.update_total_points # Use `&.` para evitar erro se user for nil
        puts "    Total de pontos do Usuário #{bet.user&.email || 'Desconhecido'} após atualização: #{bet.user&.total_points || 'N/A'}"
      end
      puts "--- [Match ##{id}] Processamento de Pontos Concluído ---\n"
    elsif !finalizado?
      Rails.logger.warn "Partida ##{id} não está finalizada. Pontos não serão calculados neste momento."
    else # finalizado? && (score_a.nil? || score_b.nil?)
      Rails.logger.warn "Partida ##{id} finalizada mas sem placares definidos. Pontos não calculados."
    end
  end

  # Renomeado de `calculate_points_for` para `calculate_single_bet_points` para clareza.
  # Esta função calcula os pontos para UMA aposta.
  def calculate_single_bet_points(bet)
    # Debugging individual conditions
    is_exact = exact_score?(bet)
    is_diff_winner = correct_winner_with_goal_difference?(bet)
    is_winner = correct_winner?(bet)

    puts "        Verificações para Aposta #{bet.id}:"
    puts "          Placar Exato? #{is_exact}"
    puts "          Vencedor com Diferença de Gols? #{is_diff_winner}"
    puts "          Vencedor Correto? #{is_winner}"

    if is_exact
      10
    elsif is_diff_winner
      7
    elsif is_winner
      5
    else
      0
    end
  end

  # Métodos auxiliares de cálculo de pontos
  # Use self.score_a e self.score_b
  def exact_score?(bet)
    result = (bet.guess_a == self.score_a && bet.guess_b == self.score_b)
    puts "          exact_score? -> Palpite: #{bet.guess_a}x#{bet.guess_b}, Placar Real: #{self.score_a}x#{self.score_b} => #{result}"
    result
  end

  # Use self.score_a e self.score_b
  def correct_winner_with_goal_difference?(bet)
    result = (bet.guess_a - bet.guess_b) == (self.score_a - self.score_b)
    puts "          correct_winner_with_goal_difference? -> Diferença Palpite: #{bet.guess_a - bet.guess_b}, Diferença Real: #{self.score_a - self.score_b} => #{result}"
    result
  end

  # Use self.score_a e self.score_b
  def correct_winner?(bet)
    bet_outcome = nil
    match_outcome = nil

    # Determina o resultado da aposta
    if bet.guess_a.present? && bet.guess_b.present?
      if bet.guess_a > bet.guess_b
        bet_outcome = :team_a_wins
      elsif bet.guess_a < bet.guess_b
        bet_outcome = :team_b_wins
      else
        bet_outcome = :draw
      end
    end

    # Determina o resultado real da partida
    if self.score_a.present? && self.score_b.present?
      if self.score_a > self.score_b
        match_outcome = :team_a_wins
      elsif self.score_a < self.score_b
        match_outcome = :team_b_wins
      else
        match_outcome = :draw
      end
    end

    result = (bet_outcome == match_outcome)
    puts "          correct_winner? -> Resultado Palpite: #{bet_outcome}, Resultado Real: #{match_outcome} => #{result}"
    result
  end

  def future_match_date
    return unless match_date.present?

    # Verifique se a partida NÃO ESTÁ finalizada para validar a data futura.
    # Se já estiver finalizada, a data pode ser no passado.
    if !finalizado? && match_date <= Time.current
      errors.add(:match_date, "deve ser no futuro para partidas não finalizadas")
    elsif match_date > 1.year.from_now
      errors.add(:match_date, "não pode ser mais de 1 ano no futuro")
    end
  end

  def validate_logo_files
    [ team_a_logo, team_b_logo ].each do |logo|
      next unless logo.attached?

      unless logo.content_type.in?(%w[image/jpeg image/png])
        errors.add(:base, "Os escudos devem ser no formato JPG ou PNG")
      end

      if logo.byte_size > 2.megabytes
        errors.add(:base, "Cada escudo deve ter no máximo 2MB")
      end
    end
  end
end