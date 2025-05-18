# app/controllers/admin/teams_controller.rb

module Admin
  class TeamsController < ApplicationController
    before_action :set_team, only: [ :show, :edit, :update, :destroy ]

    def index
      @teams = Team.all
    end

    def show; end

    def new
      @team = Team.new
    end

    def create
      @team = Team.new(team_params)

      if @team.save

        redirect_to admin_teams_path, notice: "Equipa criada com sucesso."

      else

        render :new, status: :unprocessable_entity

      end
    end

    def edit
      @team = Team.find(params[:id])
    end

    def update
      if @team.update(team_params)

        redirect_to admin_teams_path, notice: "Equipa atualizada com sucesso."

      else

        render :edit, status: :unprocessable_entity

      end
    end

    def destroy
      @team = Team.find(params[:id])

      @team.destroy

      redirect_to admin_teams_path, notice: "Time excluído com sucesso."
    end

      def remove_logo
      @team = Team.find(params[:id])
      @team.logo.purge if @team.logo.attached?
      redirect_to admin_teams_path, notice: "Logo removida com sucesso."
    end


    private

    def set_team
      @team = Team.find(params[:id])
    end

    def team_params
      params.require(:team).permit(:name, :logo)
    end
  end
end
