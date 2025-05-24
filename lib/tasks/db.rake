namespace :db do
  desc "Limpa partidas e apostas"
  task clean_matches: :environment do
    Bet.delete_all
    Match.delete_all
    puts "Partidas e apostas removidas com sucesso!"
  end
end