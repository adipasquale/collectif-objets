# frozen_string_literal: true

module Communes
  class RecensementsController < BaseController
    before_action :set_objet
    before_action :set_recensement, only: %i[edit update destroy]
    before_action :set_wizard, only: %i[edit update]

    content_security_policy(only: :edit) { |policy| policy.style_src :self, :unsafe_inline }

    def edit
      @modal = params[:modal]
    end

    def create
      commune = Commune.find(params[:commune_id])
      commune.start! if commune.inactive?

      @recensement = Recensement.new(objet: @objet, dossier: commune.dossier)
      authorize(@recensement)
      if @recensement.save
        redirect_to edit_commune_objet_recensement_path(@recensement.commune, @objet, @recensement, step: 1)
      else
        redirect_to commune_objet_path(@recensement.commune, @objet),
                    alert: "Une erreur est survenue : #{@recensement.errors.full_messages.join}"
      end
    end

    def update
      if @wizard.update(params_wizard)
        redirect_to @wizard.after_success_path
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @recensement.destroy
        redirect_to \
          commune_objet_path(@recensement.commune, @recensement.objet),
          success: "Recensement supprimé"
      else
        render :edit, status: :unprocessable_content
      end
    end

    protected

    def set_objet
      @objet = Objet.find(params[:objet_id])
    end

    def set_recensement
      @recensement = Recensement.find(params[:id])
      authorize @recensement
    end

    def set_wizard
      step = params[:step] || (@recensement.draft? ? 1 : 7)
      @wizard = RecensementWizard::Base.build_for(step, @recensement)
      @wizard.assign_attributes(params_wizard)
    end

    def params_wizard
      params[:wizard].present? ? params.require(:wizard).permit(*@wizard.permitted_params) : {}
    end

    def active_nav_links = %w[Recensement]
  end
end
