# app/models/match.rb
class Match < ApplicationRecord
  # Associações
  has_many :bets, dependent: :destroy
  belongs_to :championship
  belongs_to :team_a, class_name: "Team", optional: true
  belongs_to :team_b, class_name: "Team", optional: true
  has_one_attached :team_a_logo
  has_one_attached :team_b_logo
  belongs_to :round, optional: true

  # Enum para o status da partida
  # Define os possíveis status e o valor padrão para 'agendado'.
  # As chaves são em português, e os valores são os inteiros correspondentes.
  enum :status, {agendado: 0, em_andamento: 1, finalizado: 2, cancelado: 3}, default: :agendado

  # --- VALIDAÇÕES AJUSTADAS ---
  validates :team_a_id, :team_b_id, presence: true
  validates :team_a, :team_b, :match_date, presence: true
  validates :championship, presence: true
  
  # A validação de unicidade foi consolidada.
  # Garante que a combinação dos times A e B com a data da partida é única.
  # A ordem dos times importa para esta validação de unicidade (ex: A vs B é diferente de B vs A).
  validates :match_date, uniqueness: { scope: [:team_a_id, :team_b_id],
                                       message: "já existe uma partida agendada com esses times na mesma data." }

  # Validação para garantir que a data da partida é futura SOMENTE na criação.
  # Quando a partida é editada para inserir placares, esta validação é ignorada.
  validate :future_match_date, if: :new_record? # <--- CORREÇÃO AQUI: Aplica validação APENAS na criação

  validate :validate_logo_files
  validate :teams_must_be_different # Garante que Team A e Team B não são o mesmo

  # Callbacks
  # `after_update_commit` garante que o banco de dados já foi atualizado
  # antes de tentar calcular os pontos.
  # `if: -> { saved_change_to_status? && finalizado? }` garante que este callback
  # só roda se o status da partida mudou para 'finalizado'.
  after_update_commit :calculate_points_for_bets, if: -> { saved_change_to_status? && finalizado? }

  # Scopes
  scope :upcoming, -> { where("match_date >= ?", Time.current).order(match_date: :asc) }
  scope :past, -> { where("match_date <= ?", Time.current).order(match_date: :desc) }
  scope :with_championship, ->(limit = 5) { includes(:championship).limit(limit) }

  # Métodos de Instância
  # Verifica se a partida pode ser finalizada (útil para lógica de exibição).
  def can_be_finalized?
    !finalizado? && # Não está finalizada
      match_date.present? && # Tem data
      match_date <= Time.current && # A data já passou
      team_a.present? && # Tem time A
      team_b.present? # Tem time B
  end

  # Métodos auxiliares para nomes e logos dos times
  def team_a_name
    team_a&.name || "Time A" # Usa `&.` para evitar erro se team_a for nil
  end

  def team_b_name
    team_b&.name || "Time B" # Usa `&.` para evitar erro se team_b for nil
  end

  def team_a_logo_or_default
    # Prioriza o logo do time associado, depois o logo direto da partida, senão um default.
    team_a&.logo.attached? ? team_a.logo : (team_a_logo.attached? ? team_a_logo : "default_team.png")
  end

  def team_b_logo_or_default
    # Prioriza o logo do time associado, depois o logo direto da partida, senão um default.
    team_b&.logo.attached? ? team_b.logo : (team_b_logo.attached? ? team_b_logo : "default_team.png")
  end

  private

  # Método para calcular e atualizar os pontos de todas as apostas da partida.
  def calculate_points_for_bets
    # Só calcula se a partida está finalizada E tem placares válidos.
    if finalizado? && score_a.present? && score_b.present?
      puts "\n--- [Match ##{id}] Processando Pontos para apostas (STATUS FINALIZADO) ---"
      puts "Placar da Partida: #{self.score_a} x #{self.score_b}"

      # Itera sobre cada aposta associada a esta partida, incluindo o usuário para evitar N+1.
      bets.includes(:user).find_each do |bet|
        puts "    [Bet ##{bet.id}] Processando Aposta do Usuário #{bet.user&.display_name || 'Desconhecido'} (Palpite: #{bet.guess_a} x #{bet.guess_b})"

        points = calculate_single_bet_points(bet) # Chama o método para calcular pontos de uma única aposta
        puts "    Pontos calculados para aposta #{bet.id}: #{points}"

        # Atualiza a coluna `points` da aposta. `update_column` ignora callbacks e validações,
        # sendo eficiente para atualizações em massa.
        if bet.points != points
          puts "    Atualizando pontos da aposta #{bet.id} de #{bet.points} para #{points}"
          bet.update_column(:points, points)
        else
          puts "    Pontos da aposta #{bet.id} já são #{points}. Nenhuma atualização necessária."
        end

        # Chama o método no User para atualizar o total de pontos do usuário.
        # `&.` evita erro se `bet.user` for nil.
        bet.user&.update_total_points
        puts "    Total de pontos do Usuário #{bet.user&.display_name || 'Desconhecido'} após atualização: #{bet.user&.total_points || 'N/A'}"
      end
      puts "--- [Match ##{id}] Processamento de Pontos Concluído ---\n"
    elsif !finalizado?
      Rails.logger.warn "Partida ##{id} não está finalizada. Pontos não serão calculados neste momento."
    else # finalizado? && (score_a.nil? || score_b.nil?)
      Rails.logger.warn "Partida ##{id} finalizada mas sem placares definidos. Pontos não calculados."
    end
  end

  # Calcula os pontos para uma única aposta com base no resultado da partida.
  def calculate_single_bet_points(bet)
    is_exact = exact_score?(bet)
    is_diff_winner = correct_winner_with_goal_difference?(bet)
    is_winner = correct_winner?(bet)

    puts "          Verificações para Aposta #{bet.id}:"
    puts "            Placar Exato? #{is_exact}"
    puts "            Vencedor com Diferença de Gols? #{is_diff_winner}"
    puts "            Vencedor Correto? #{is_winner}"

    if is_exact
      10 # Pontos para placar exato
    elsif is_diff_winner
      7 # Pontos para vencedor e diferença de gols corretos
    elsif is_winner
      5 # Pontos para vencedor correto
    else
      0 # Nenhum ponto
    end
  end

  # Verifica se o palpite da aposta corresponde exatamente ao placar final.
  def exact_score?(bet)
    result = (bet.guess_a == self.score_a && bet.guess_b == self.score_b)
    puts "            exact_score? -> Palpite: #{bet.guess_a}x#{bet.guess_b}, Placar Real: #{self.score_a}x#{self.score_b} => #{result}"
    result
  end

  # Verifica se a diferença de gols do palpite corresponde à diferença de gols real,
  # e se o vencedor está correto.
  def correct_winner_with_goal_difference?(bet)
    # Garante que ambos os placares estão presentes para evitar erros de cálculo.
    return false unless bet.guess_a.present? && bet.guess_b.present? && self.score_a.present? && self.score_b.present?

    bet_diff = bet.guess_a - bet.guess_b
    match_diff = self.score_a - self.score_b

    # Verifica se a diferença de gols é a mesma E se o vencedor é o mesmo.
    # Ex: 2x1 (diff 1) e 3x2 (diff 1) - vencedor é o mesmo.
    # Ex: 2x0 (diff 2) e 3x1 (diff 2) - vencedor é o mesmo.
    result = (bet_diff == match_diff) && correct_winner?(bet)
    puts "            correct_winner_with_goal_difference? -> Diferença Palpite: #{bet_diff}, Diferença Real: #{match_diff} => #{result}"
    result
  end

  # Verifica se o vencedor (ou empate) do palpite corresponde ao vencedor (ou empate) real.
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
    puts "            correct_winner? -> Resultado Palpite: #{bet_outcome}, Resultado Real: #{match_outcome} => #{result}"
    result
  end

  # Valida que a data da partida deve ser no futuro apenas na criação de um novo registro.
  # Permite que partidas existentes (com data no passado) tenham seus placares inseridos.
  def future_match_date
    return unless match_date.present?

    if match_date <= Time.current
      errors.add(:match_date, "deve ser no futuro ao agendar uma nova partida.")
    elsif match_date > 1.year.from_now
      errors.add(:match_date, "não pode ser mais de 1 ano no futuro.")
    end
  end

  # Valida os arquivos de logo anexados (tipo e tamanho).
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

  # Valida que os times da partida devem ser diferentes.
  def teams_must_be_different
    if team_a_id.present? && team_b_id.present? && team_a_id == team_b_id
      errors.add(:base, "Os times da partida devem ser diferentes.")
    end
  end
end