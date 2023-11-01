# frozen_string_literal: true

# rubocop:disable Rails/OutputSafety
module CommuneHelper
  def commune_status_badge(commune)
    color = { inactive: "", started: :info, completed: :success }
      .with_indifferent_access[commune.status]
    text = I18n.t("activerecord.attributes.commune.statuses.#{commune.status}")
    "<p class=\"fr-badge fr-badge--sm fr-badge--#{color}\">#{text}</p>".html_safe
  end

  def commune_messagerie_title(commune)
    if commune.messages.count.positive?
      "Messagerie (#{commune.messages.count})"
    else
      "Messagerie"
    end
  end

  def commune_recenser_objets_text(commune)
    text = commune.objets.count > 1 ? "Recenser les objets" : "Recenser l’objet"
    text + " de #{commune.nom}"
  end

  def communes_statuses_options_for_select
    [
      ["Tout sélectionner", ""],
      [Commune::STATUT_GLOBAL_EXAMINÉ, Commune::ORDRE_EXAMINÉ],
      [Commune::STATUT_GLOBAL_EN_COURS_D_EXAMEN, Commune::ORDRE_EN_COURS_D_EXAMEN],
      [Commune::STATUT_GLOBAL_REPONSE_AUTOMATIQUE, Commune::ORDRE_REPONSE_AUTOMATIQUE],
      [Commune::STATUT_GLOBAL_A_EXAMINER, Commune::ORDRE_A_EXAMINER],
      [Commune::STATUT_GLOBAL_EN_COURS_DE_RECENSEMENT, Commune::ORDRE_EN_COURS_DE_RECENSEMENT],
      [Commune::STATUT_GLOBAL_NON_RECENSÉ, Commune::ORDRE_NON_RECENSÉ]
    ]
  end

  def commune_statut_global_badge(commune, small: false)
    colors = ["", "", "blue-ecume", "blue-ecume", "success"]
    content_tag(
      "p",
      commune.statut_global_texte,
      class: "fr-badge fr-badge--#{colors[commune.statut_global]} #{small ? 'fr-badge--sm' : ''}"
    )
  end
end
# rubocop:enable Rails/OutputSafety
