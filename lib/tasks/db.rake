# lib/tasks/clean_data.rake
namespace :db do
  desc "Limpa todos os dados de partidas, apostas, rodadas, times e campeonatos"
  task clean_all: :environment do
    puts "Removendo apostas..."
    Bet.destroy_all
    puts "Removendo partidas..."
    Match.destroy_all
    puts "Removendo rodadas..."
    Round.destroy_all
    # puts "Removendo times..."
    # Team.destroy_all
    puts "Removendo campeonatos..."
    Championship.destroy_all
    puts "Todos os dados do bolão foram limpos com sucesso!"
  end
end