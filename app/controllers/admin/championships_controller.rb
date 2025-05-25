module Admin
  class ChampionshipsController < ApplicationController
    before_action :authenticate_user!
    before_action :verify_admin
    before_action :set_championship, only: [ :show, :edit, :update, :destroy, :edit_teams, :update_teams ]

  # Para listar apenas campeonatos ativos:
    @active_championships = Championship.active

  # Para listar campeonatos finalizados:
    @inactive_championships = Championship.inactive

    def index
      @championships = Championship.all.order(name: :asc)
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
        # Redireciona para a página de detalhes do campeonato recém-criado
        redirect_back fallback_location: admin_championships_path,
              notice: 'Campeonato criado com sucesso.'
      else
        # Se houver erros de validação, renderiza novamente o formulário 'new'
        # para que as mensagens de erro sejam exibidas.
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
      permitted = [:name, :start_date, :end_date, :description]
      permitted << :active unless action_name == 'create'
      params.require(:championship).permit(permitted)
    end

    def verify_admin
      redirect_to root_path, alert: "Acesso não autorizado" unless current_user.admin?
    end
  end
end
