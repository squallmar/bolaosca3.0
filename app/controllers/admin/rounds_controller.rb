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
      # Partidas da rodada, ordenadas por data e times para melhor visualização
      @matches = @round.matches.order(match_date: :asc, team_a_id: :asc)
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
      # Antes de destruir, verifique se há partidas associadas para evitar erro no `dependent: :nullify`
      # Embora `dependent: :nullify` no modelo Round teoricamente já cuide disso, é bom ter certeza.
      if @round.matches.exists?
        # Se quiser permitir a exclusão mesmo com partidas, remova este if/else ou modifique-o
        # Se você permitir a exclusão, `round_id` nas partidas será nulo.
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

    def round_params
      params.require(:round).permit(:number, :status, :finalized_at)
      # Nota: geralmente 'status' e 'finalized_at' não são permitidos via formulário
      # de criação/edição comum. O `finalize!` cuida disso.
      # Se você quer permitir a alteração manual via admin, mantenha.
      # Caso contrário, remova `:status, :finalized_at` daqui e use o `finalize!`
      # para a finalização.
    end
  end
end