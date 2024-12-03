# frozen_string_literal: true

module Communes
  class RecensementPhotosController < BaseController
    before_action :set_recensement_and_authorize
    before_action :set_photo, only: %i[destroy]

    def create
      return render "communes/recensements/edit" unless @wizard.update(permitted_params)

      respond_to do |format|
        format.html { redirect_to_edit }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              "attached-photos-wrapper",
              partial: "communes/recensements/photo",
              locals: { recensement: @recensement, photo: @recensement.photos.last, delete_button: true }
            ),
            turbo_stream.replace(
              "upload_form",
              PhotoUploadComponent
                .new(url: commune_objet_recensement_photos_path(@recensement.commune, @recensement.objet, @recensement))
                .render_in(view_context)
            )
          ]
        end
      end
    end

    def destroy
      @photo.purge
      @recensement.update!(photos_count: @recensement.photos_count - 1)

      respond_to do |format|
        format.html { redirect_to_edit }
        format.turbo_stream do
          render turbo_stream: [turbo_stream.remove("photo-#{@photo.id}")]
        end
      end
    end

    private

    def redirect_to_edit
      redirect_to(edit_commune_objet_recensement_path(@recensement.commune,
                                                      @recensement.objet,
                                                      @recensement,
                                                      step: RecensementWizard::PHOTOS_STEP_NUMER))
    end

    def set_recensement_and_authorize
      @recensement = Recensement.find(params[:recensement_id])
      @wizard = RecensementWizard::Base.build_for(RecensementWizard::PHOTOS_STEP_NUMER, @recensement)
      authorize(@recensement, :update?)
    end

    def set_photo
      photo_id = params[:id]
      @photo = ActiveStorage::Attachment.find(photo_id)
    end

    def permitted_params
      c = params.require(:recensement).permit(photos: [])
      c[:photos] = c[:photos].map(&:presence).compact if c[:photos].any?
      c
    end
  end
end
