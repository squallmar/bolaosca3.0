# app/models/match.rb
class Match < ApplicationRecord
  has_many :bets, dependent: :destroy
  belongs_to :championship
  belongs_to :team_a, class_name: "Team", optional: true
  belongs_to :team_b, class_name: "Team", optional: true
  has_one_attached :team_a_logo
  has_one_attached :team_b_logo
  belongs_to :round, optional: true

  enum :status, {agendado: 0, em_andamento: 1, finalizado: 2, cancelado: 3}, default: :agendado

  # --- VALIDAÇÕES AJUSTADAS ---
  validates :team_a_id, :team_b_id, presence: true
  validates :team_a, :team_b, :match_date, presence: true
  validates :championship, presence: true
  
  # A validação de unicidade foi consolidada.
  # Garante que a combinação dos times A e B com a data da partida é única.
  # Nota: Se "Time A vs Time B" deve ser diferente de "Time B vs Time A"
  # isso está ok. Se for o mesmo jogo, precisaríamos de uma validação mais complexa.
  # Pelo seu código, parece que a ordem importa para a unicidade.
  validates :match_date, uniqueness: { scope: [:team_a_id, :team_b_id],
                                       message: "já existe uma partida agendada com esses times na mesma data." }


  validate :future_match_date
  validate :validate_logo_files
  validate :teams_must_be_different # Nova validação para garantir que Team A e Team B são diferentes

  scope :upcoming, -> { where("match_date >= ?", Time.current).order(match_date: :asc) }
  scope :past, -> { where("match_date <= ?", Time.current).order(match_date: :desc) }
  scope :with_championship, ->(limit = 5) { includes(:championship).limit(limit) }

  after_update_commit :calculate_points_for_bets, if: -> { saved_change_to_status? && finalizado? }

  def can_be_finalized?
    !finalizado? &&
      match_date.present? &&
      match_date <= Time.current &&
      team_a.present? &&
      team_b.present?
  end

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

  def calculate_points_for_bets
    if finalizado? && score_a.present? && score_b.present?
      puts "\n--- [Match ##{id}] Processando Pontos para apostas (STATUS FINALIZADO) ---"
      puts "Placar da Partida: #{self.score_a} x #{self.score_b}"

      bets.includes(:user).find_each do |bet|
        puts "    [Bet ##{bet.id}] Processando Aposta do Usuário #{bet.user&.email || 'Desconhecido'} (Palpite: #{bet.guess_a} x #{bet.guess_b})"

        points = calculate_single_bet_points(bet)
        puts "    Pontos calculados para aposta #{bet.id}: #{points}"

        if bet.points != points
          puts "    Atualizando pontos da aposta #{bet.id} de #{bet.points} para #{points}"
          bet.update_column(:points, points)
        else
          puts "    Pontos da aposta #{bet.id} já são #{points}. Nenhuma atualização necessária."
        end

        bet.user&.update_total_points
        puts "    Total de pontos do Usuário #{bet.user&.email || 'Desconhecido'} após atualização: #{bet.user&.total_points || 'N/A'}"
      end
      puts "--- [Match ##{id}] Processamento de Pontos Concluído ---\n"
    elsif !finalizado?
      Rails.logger.warn "Partida ##{id} não está finalizada. Pontos não serão calculados neste momento."
    else # finalizado? && (score_a.nil? || score_b.nil?)
      Rails.logger.warn "Partida ##{id} finalizada mas sem placares definidos. Pontos não calculados."
    end
  end

  def calculate_single_bet_points(bet)
    is_exact = exact_score?(bet)
    is_diff_winner = correct_winner_with_goal_difference?(bet)
    is_winner = correct_winner?(bet)

    puts "          Verificações para Aposta #{bet.id}:"
    puts "            Placar Exato? #{is_exact}"
    puts "            Vencedor com Diferença de Gols? #{is_diff_winner}"
    puts "            Vencedor Correto? #{is_winner}"

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

  def exact_score?(bet)
    result = (bet.guess_a == self.score_a && bet.guess_b == self.score_b)
    puts "            exact_score? -> Palpite: #{bet.guess_a}x#{bet.guess_b}, Placar Real: #{self.score_a}x#{self.score_b} => #{result}"
    result
  end

  def correct_winner_with_goal_difference?(bet)
    result = (bet.guess_a - bet.guess_b) == (self.score_a - self.score_b)
    puts "            correct_winner_with_goal_difference? -> Diferença Palpite: #{bet.guess_a - bet.guess_b}, Diferença Real: #{self.score_a - self.score_b} => #{result}"
    result
  end

  def correct_winner?(bet)
    bet_outcome = nil
    match_outcome = nil

    if bet.guess_a.present? && bet.guess_b.present?
      if bet.guess_a > bet.guess_b
        bet_outcome = :team_a_wins
      elsif bet.guess_a < bet.guess_b
        bet_outcome = :team_b_wins
      else
        bet_outcome = :draw
      end
    end

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
    puts "            correct_winner? -> Resultado Palpite: #{bet_outcome}, Resultado Real: #{match_outcome} => #{result}"
    result
  end

  def future_match_date
    return unless match_date.present?

    # Esta validação agora só se aplica ao criar ou atualizar uma partida que AINDA NÃO ESTÁ finalizada.
    # Se a partida JÁ ESTÁ finalizada, a data pode ser no passado, o que é normal.
    if !finalizado?
      if match_date <= Time.current
        errors.add(:match_date, "deve ser no futuro para partidas não finalizadas")
      elsif match_date > 1.year.from_now
        errors.add(:match_date, "não pode ser mais de 1 ano no futuro")
      end
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

  # Adiciona uma validação para garantir que Team A e Team B não são o mesmo
  def teams_must_be_different
    if team_a_id.present? && team_b_id.present? && team_a_id == team_b_id
      errors.add(:base, "Os times da partida devem ser diferentes.")
    end
  end
end