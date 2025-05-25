# app/controllers/admin/bets_controller.rb
class Admin::BetsController < Admin::BaseController
  def index
    @bets = Bet.all.order(created_at: :desc).page(params[:page])
  end
end