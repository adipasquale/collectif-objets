# frozen_string_literal: true

module Conservateurs
  class CommunesController < ApplicationController
    before_action :set_commune, :restrict_access, :set_dossier, only: [:show]
    before_action :restrict_access_autocomplete, only: %i[autocomplete index]
    before_action :set_departement, only: [:index]

    def index
      @communes_search = Co::Conservateurs::CommunesSearch.new(@departement, params)
    end

    def show
      @objets = compute_objets
      return true if params[:analyse_saved].blank?

      @objets = @objets.where(recensements: { analysed_at: nil })
      render "show_analyse_saved"
    end

    def autocomplete
      render_turbo_stream_update(
        "js-header-search-results",
        partial: "conservateurs/communes/autocomplete_results",
        locals: { communes: communes_autocomplete_arel, search_query: params[:nom] }
      )
    end

    protected

    def set_commune
      @commune = Commune.find(params[:id])
    end

    def set_dossier
      @dossier = @commune.dossier
    end

    def set_departement
      @departement = params[:departement_id]
    end

    def restrict_access
      if current_conservateur.nil?
        redirect_to root_path, alert: "Veuillez vous connecter en tant que conservateur"
      elsif current_conservateur.departements.exclude?(@commune.departement)
        redirect_to root_path, alert: "Vous n'avez pas accès au département de cette commune"
      end
    end

    def restrict_access_autocomplete
      return true if current_conservateur.present?

      redirect_to root_path, alert: "Veuillez vous connecter en tant que conservateur"
    end

    def compute_objets
      if @dossier&.full?
        return @dossier.objets
          .order_by_recensement_priorite
          .includes(:commune, recensements: %i[photos_attachments photos_blobs])
      end
      @commune.objets
        .with_photos_first
        .includes(:commune, recensements: %i[photos_attachments photos_blobs])
    end

    def communes_autocomplete_arel
      Commune
        .where(departement: current_conservateur.departements)
        .search_by_nom(params[:nom])
        .order("nom ASC")
        .first(5)
    end
  end
end
