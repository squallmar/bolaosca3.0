class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!

  def termos
    @page_title = "Termos de Uso"
  end

  def privacidade
    @page_title = "Política de Privacidade"
  end
end
