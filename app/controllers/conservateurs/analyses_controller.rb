# frozen_string_literal: true

module Conservateurs
  class AnalysesController < BaseController
    before_action :set_recensement, :set_dossier, :set_analyse, :set_objet

    def edit; end

    def update
      if @recensement.update(analyse_recensement_params)
        redirect_to conservateurs_commune_path(@objet.commune, analyse_saved: true)
      else
        render :edit, status: :unprocessable_content
      end
    end

    protected

    def set_recensement
      @recensement = Recensement.includes(dossier: [:commune]).find(params[:recensement_id])
      @recensement_presenter = RecensementPresenter.new(@recensement) if @recensement
    end

    def set_analyse
      @analyse = Analyse.new(recensement: @recensement)
      authorize(@analyse)
    end

    def set_objet
      @objet = @recensement.objet
    end

    def set_dossier
      @dossier = @recensement.dossier
    end

    def analyse_recensement_params
      @analyse_recensement_params ||=
        Co::Recensements::AnalyseParamsParser.new(params).parse.merge(conservateur_id: current_conservateur.id)
    end

    def active_nav_links = ["Mes départements", @dossier.departement.to_s]
  end
end
