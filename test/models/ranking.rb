class Ranking < ApplicationRecord
  def self.update_all_rankings
    # Ordena usuários por pontos (maior primeiro)
    users = User.order(total_points: :desc)

    # Atualiza a posição de cada usuário
    users.each_with_index do |user, index|
      user.update(ranking_position: index + 1)
    end
  end
end
