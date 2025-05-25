# app/controllers/matches_controller.rb
class MatchesController < ApplicationController
  before_action :authenticate_user!
  # O check_admin é aplicado a todas as ações, exceto index e show.
  # Isso significa que new, create, edit, update, destroy são restritas a admins.
  before_action :check_admin, except: [ :index, :show ]
  before_action :set_match, only: [ :show, :edit, :update, :destroy ]

  # NOVO: Carrega as rodadas para as ações que precisam delas no formulário
  before_action :load_rounds, only: [ :new, :create, :edit, :update ]
  # Já existentes:
  before_action :load_championships, only: [ :new, :create, :edit, :update ]
  before_action :load_teams, only: [ :new, :create, :edit, :update ]


  def index
    @upcoming_matches = Match.upcoming
      .includes(:championship, :bets, :team_a, :team_b, :round, # Inclua :round aqui para evitar N+1 queries
                team_a_logo_attachment: :blob, team_b_logo_attachment: :blob)
      .order(match_date: :asc)

    @past_matches = Match.past
      .includes(:championship, :bets, :team_a, :team_b, :round, # Inclua :round aqui
                team_a_logo_attachment: :blob, team_b_logo_attachment: :blob)
      .order(match_date: :desc)

    if user_signed_in?
      @user_bets = current_user.bets.where(match_id: (@upcoming_matches + @past_matches).pluck(:id)).index_by(&:match_id)
    end
  end

  def show
    @bets = @match.bets.includes(:user)
  end

  def new
    @match = Match.new(
      match_date: Time.current.beginning_of_hour + 1.day,
      team_a_id: Team.first&.id,
      team_b_id: Team.second&.id
    )
    # @rounds, @championships, @teams já são carregados pelos before_actions
  end

  def create
    @match = Match.new(match_params)

    if @match.save
      attach_logos # Se esta lógica ainda for necessária para logos de partida
      redirect_to matches_path, notice: "Partida criada com sucesso!"
    else
      # load_championships, load_teams, load_rounds já são executados pelo before_action
      # antes de renderizar :new novamente, então não precisa chamá-los aqui.
      flash.now[:alert] = "Erro ao criar partida: #{@match.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @match já é definido por set_match
    # @championships, @teams, @rounds já são carregados pelos before_actions
    # As linhas abaixo podem ser removidas se não forem estritamente necessárias para preencher defaults
    # em casos específicos de edição (o formulário já deve carregar os valores existentes do @match)
    # @match.team_a.name ||= Team.first.name # Isso não é como se define defaults para um formulário
    # @match.team_b.name ||= Team.second.name # O formulário já mostra o nome do time associado
    # @match.match_date ||= Time.current.beginning_of_hour + 1.day # O formulário já mostra a data existente
    # @match.location ||= "Local da partida" # O formulário já mostra o local existente
  end

  def update
    if @match.update(match_params)
      attach_logos # Se esta lógica ainda for necessária para logos de partida
      redirect_to @match, notice: "Partida atualizada com sucesso!"
    else
      # load_championships, load_teams, load_rounds já são executados pelo before_action
      flash.now[:alert] = "Erro ao atualizar partida: #{@match.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @match.destroy
    redirect_to matches_path, notice: "Partida removida com sucesso!"
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end

  def load_championships
    @championships = Championship.order(:name)
  end

  def load_teams
    @teams = Team.order(:name)
  end

  # NOVO: Método para carregar as rodadas
  def load_rounds
    @rounds = Round.all.order(:number)
  end

  def match_params
    params.require(:match).permit(
      :championship_id,
      :team_a_id,
      :team_b_id,
      :match_date,
      :location,
      :notes,
      :round_id, # <--- ADICIONADO: Permite o round_id
      :team_a_logo, # Permite upload de arquivo para team_a_logo
      :team_b_logo  # Permite upload de arquivo para team_b_logo
      # Removido :team_a, :team_b pois são associações, não parâmetros diretos para permitir
    )
  end

  def attach_logos
    # Esta lógica é para anexar logos diretamente à partida (se ela tiver has_one_attached :team_a_logo)
    # Se os logos são dos times (Team model), esta lógica pode ser redundante ou estar em outro local.
    # Assumindo que team_a_logo e team_b_logo são attachments do Match.
    # A condição `unless @match.team_a || @match.team_b` parece estranha aqui,
    # pois team_a_id e team_b_id são obrigatórios.
    # Se a intenção é permitir upload de logo *para a partida* se o time associado não tiver logo,
    # a lógica precisaria ser mais específica.
    # Por enquanto, mantive a estrutura, mas é um ponto a revisar se não funcionar como esperado.
    @match.team_a_logo.attach(params[:match][:team_a_logo]) if params[:match][:team_a_logo].present?
    @match.team_b_logo.attach(params[:match][:team_b_logo]) if params[:match][:team_b_logo].present?
  end

  def check_admin
    redirect_to matches_path, alert: "Acesso não autorizado" unless current_user&.admin?
  end
end