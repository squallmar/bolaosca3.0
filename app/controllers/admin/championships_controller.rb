module Admin
  class ChampionshipsController < ApplicationController
    before_action :authenticate_user!
    before_action :verify_admin
    before_action :set_championship, only: [:show, :edit, :update, :destroy, :edit_teams, :update_teams]

    def index
      @championships = Championship.all.order(name: :asc)
      @active_championships = Championship.active
      @inactive_championships = Championship.inactive
      
      respond_to do |format|
        format.html 
        format.json { render json: @championships }
      end
    end

    def show
    end

    def new
      @championship = Championship.new
    end

    def create
      @championship = Championship.new(championship_params)
      
      if @championship.save
        redirect_to admin_championships_path, notice: 'Campeonato criado!'
      else
        render :new, status: :unprocessable_entity
      end
    end
       
    def edit
      @championship = Championship.find(params[:id])
    end

    def update
      if @championship.update(championship_params)
        redirect_to admin_championships_path, notice: "Campeonato atualizado com sucesso."
      else
        render :edit
      end
    end

    def destroy
      @championship.teams.clear
      @championship.destroy
      redirect_to admin_championships_path, notice: "Campeonato removido!"
    end

    def edit_teams
      @teams = Team.all.order(name: :asc)
    end

    def update_teams
      team_ids = params[:championship][:team_ids].reject(&:blank?)
      @championship.teams = Team.where(id: team_ids)

      redirect_to admin_championships_path, notice: "Times do campeonato atualizados."
    end

    private

    def set_championship
      @championship = Championship.find(params[:id])
    end

    def championship_params
      permitted = [:name, :start_date, :end_date, :description]
      permitted += [:active] if [:edit, :update].include?(action_name.to_sym)
      params.require(:championship).permit(*permitted)
    end

    def verify_admin
      redirect_to root_path, alert: "Acesso não autorizado" unless current_user.admin?
    end
  end
end