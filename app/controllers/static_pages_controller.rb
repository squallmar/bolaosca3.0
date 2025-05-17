class StaticPagesController < ApplicationController
  
  def termos
    @page_title = "Termos de Uso"
  end

  def regras
    @page_title = "Regras do Jogo"
  end

  def sobre
    @page_title = "Sobre o Jogo"
  end

  def ajuda
    @page_title = "Ajuda"
  end

  def contato
    @page_title = "Contato"
  end

  def privacidade
    @page_title = "Política de Privacidade"
  end
end
