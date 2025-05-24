# app/models/match.rb
class Match < ApplicationRecord
  has_many :bets, dependent: :destroy
  belongs_to :championship
  belongs_to :team_a, class_name: "Team", optional: true
  belongs_to :team_b, class_name: "Team", optional: true
  has_one_attached :team_a_logo
  has_one_attached :team_b_logo

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

  # callback será disparado quando o status mudar para finalizado!
  after_update :update_rankings, if: :saved_change_to_status?

  def can_be_finalized?
    !finalizado? &&
      match_date.present? &&
      match_date <= Time.current &&
      team_a.present? &&
      team_b.present?
  end

  def finalize!(home_score, away_score)
    # atualiza os scores e o status, e dispara o `after_update :update_rankings`
    update(
      score_a: home_score,
      score_b: away_score,
      status: :finalizado,
      finalized_at: Time.current
    )
  end

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

  def update_rankings
    # só roda se a partida foi finalizada
    return unless finalizado?

    puts "\n--- Processando Ranking para Partida #{self.id} (Finalizada) ---"
    puts "Placar da Partida: #{self.score_a} x #{self.score_b}"

    bets.includes(:user).find_each do |bet|
      puts "  Processando Aposta #{bet.id} do Usuário #{bet.user.email} (Palpite: #{bet.guess_a} x #{bet.guess_b})"

      points = calculate_points_for(bet) # Chama a lógica de cálculo de pontos
      puts "  Pontos calculados para aposta #{bet.id}: #{points}"

      if bet.points != points
        puts "  Atualizando pontos da aposta #{bet.id} de #{bet.points} para #{points}"
        bet.update_column(:points, points) # Salva os pontos na aposta (update_column para evitar callbacks e validações)
      else
        puts "  Pontos da aposta #{bet.id} já são #{points}. Nenhuma atualização necessária."
      end

      # Chama o método no User para atualizar o total de pontos
      bet.user.update_total_points
      puts "  Total de pontos do Usuário #{bet.user.email} após atualização: #{bet.user.total_points}"
    end
    puts "--- Fim do Processamento de Ranking para Partida #{self.id} ---\n"
  end

  def calculate_points_for(bet)
    # Debugging individual conditions
    is_exact = exact_score?(bet)
    is_diff_winner = correct_winner_with_goal_difference?(bet)
    is_winner = correct_winner?(bet)

    puts "    Verificações para Aposta #{bet.id}:"
    puts "      Placar Exato? #{is_exact}"
    puts "      Vencedor com Diferença de Gols? #{is_diff_winner}"
    puts "      Vencedor Correto? #{is_winner}"

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

  # Use self.score_a e self.score_b
  def exact_score?(bet)
    result = (bet.guess_a == self.score_a && bet.guess_b == self.score_b)
    puts "      exact_score? -> Palpite: #{bet.guess_a}x#{bet.guess_b}, Placar Real: #{self.score_a}x#{self.score_b} => #{result}"
    result
  end

  # Use self.score_a e self.score_b
  def correct_winner_with_goal_difference?(bet)
    result = (bet.guess_a - bet.guess_b) == (self.score_a - self.score_b)
    puts "      correct_winner_with_goal_difference? -> Diferença Palpite: #{bet.guess_a - bet.guess_b}, Diferença Real: #{self.score_a - self.score_b} => #{result}"
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
    puts "      correct_winner? -> Resultado Palpite: #{bet_outcome}, Resultado Real: #{match_outcome} => #{result}"
    result
  end

  def future_match_date
    return unless match_date.present?

    if match_date <= Time.current && !finalizado?
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