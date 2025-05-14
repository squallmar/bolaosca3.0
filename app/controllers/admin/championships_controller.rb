module Admin
  class ChampionshipsController < ApplicationController
    before_action :authenticate_user!
    before_action :verify_admin
    before_action :set_championship, only: [ :show, :edit, :update, :destroy, :edit_teams, :update_teams ]

    def index
      @championships = Championship.all.order(name: :asc)
    end

    def show
    end

    def new
      @championship = Championship.new
    end

    def create
      @championship = Championship.new(championship_params)

      if @championship.save
        redirect_to new_path, notice: "Campeonato criado com sucesso." # VERIFICAR SE O CAMPEONATO CRIADO É O ÚLTIMO!!!!!!!!!!!!!
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @championship.update(championship_params)
        redirect_to admin_championships_path, notice: "Campeonato atualizado com sucesso."
      else
        render :edit
      end
    end

    def destroy
      @championship.destroy
      redirect_to admin_championships_path, notice: "Campeonato removido com sucesso."
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
      params.require(:championship).permit(:name, :start_date, :end_date, :description)
    end

    def verify_admin
      redirect_to root_path, alert: "Acesso não autorizado" unless current_user.admin?
    end
  end
end
