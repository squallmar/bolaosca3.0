# app/controllers/admin/rounds_controller.rb
module Admin
  class RoundsController < Admin::BaseController # Assumindo que você tem um BaseController para admin
    before_action :set_round, only: [:show, :edit, :update, :destroy, :finalize]

    # GET /admin/rounds
    def index
      @rounds = Round.order(number: :asc)
    end

    # GET /admin/rounds/1
    def show
      # ATENÇÃO AQUI: Inclua as associações das partidas para evitar N+1 queries na view
      # Isso já está correto no seu código.
      @matches = @round.matches.includes(:team_a, :team_b, :championship)
                        .order(match_date: :asc, team_a_id: :asc)
    end

    # GET /admin/rounds/new
    def new
      @round = Round.new
    end

    # GET /admin/rounds/1/edit
    def edit
    end

    # POST /admin/rounds
    def create
      @round = Round.new(round_params)

      if @round.save
        redirect_to admin_round_path(@round), notice: 'Rodada criada com sucesso.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /admin/rounds/1
    def update
      if @round.update(round_params)
        redirect_to admin_round_path(@round), notice: 'Rodada atualizada com sucesso.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/rounds/1
    def destroy
      if @round.matches.exists?
        redirect_to admin_rounds_path, alert: 'Não é possível excluir uma rodada que possui partidas associadas. Remova as partidas ou reasocie-as primeiro.'
      elsif @round.destroy
        redirect_to admin_rounds_path, notice: 'Rodada excluída com sucesso.'
      else
        redirect_to admin_rounds_path, alert: 'Erro ao excluir a rodada.'
      end
    end

    # PATCH /admin/rounds/1/finalize
    def finalize
      if @round.finalized?
        redirect_to admin_round_path(@round), alert: 'Esta rodada já está finalizada.'
      elsif @round.finalize!
        # O método `finalize!` no modelo Round já cuida de atualizar o status
        # e disparar a finalização das partidas e cálculo de pontos.
        redirect_to admin_round_path(@round), notice: 'Rodada finalizada com sucesso! Partidas associadas estão sendo processadas.'
      else
        redirect_to admin_round_path(@round), alert: 'Não foi possível finalizar a rodada.'
      end
    end

    private

    def set_round
      @round = Round.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_rounds_path, alert: 'Rodada não encontrada.'
    end

    # AJUSTADO: Permite apenas o 'number' para criação/edição via formulário.
    # O 'status' e 'finalized_at' são controlados pelo método `finalize!`.
    def round_params
      params.require(:round).permit(:number)
    end
  end
end