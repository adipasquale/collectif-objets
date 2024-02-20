# frozen_string_literal: true

class ObjetCardComponent < ViewComponent::Base
  using HTMLAttributesUtils

  with_collection_parameter :objet

  def initialize(objet = nil, **kwargs)
    @objet = objet || kwargs[:objet]
    @header_badges = kwargs[:header_badges]
    @start_badges = kwargs[:start_badges]
    @path = kwargs[:path]
    @main_photo = kwargs[:main_photo]
    @tags = kwargs[:tags]
    @commune = kwargs[:commune] || @objet.commune # pass to avoid n+1 queries
    @main_photo_origin = kwargs[:main_photo_origin] || :memoire
    @link_html_attributes_custom = kwargs[:link_html_attributes] || {}
    @recensement = kwargs[:recensement]
    super
  end

  private

  attr_reader :objet, :header_badges, :start_badges, :tags, :commune, :main_photo_origin

  delegate :nom, :palissy_DENO, :edifice_nom, :palissy_photos_presenters, to: :objet

  def path
    @path ||= objet_path(@objet)
  end

  def truncated_nom
    truncate(nom || palissy_DENO, length: 30)
  end

  def main_photo
    return @main_photo if @main_photo.present?

    case main_photo_origin
    when :recensement
      main_photo_recensement
    when :memoire
      main_photo_palissy
    when :recensement_or_memoire
      main_photo_recensement || main_photo_palissy
    end
  end

  def link_html_attributes
    { class: "fr-card__link" }
      .deep_merge_html_attributes(@link_html_attributes_custom)
      .deep_tidy_html_attributes
  end

  def main_photo_palissy = palissy_photos_presenters&.first

  def main_photo_recensement
    return unless recensement&.photos&.any?

    PhotoPresenter.new \
      url: recensement.photos.first.variant(:medium),
      description: "Photo de recensement de l’objet #{objet.nom}"
  end

  def recensement
    @recensement ||= @objet.current_recensement
  end
end
