# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
ActiveAdmin.register Objet do
  menu label: "🖼 Objets", priority: 4
  decorate_with ObjetDecorator

  actions :all, except: %i[destroy new create edit update]

  index do
    id_column
    column :palissy_REF
    column :palissy_TICO
    column :commune
    column :palissy_EDIF
    column :palissy_EMPL
    column :palissy_photos_img
    column :palissy_CATE
    column :palissy_SCLE
    column :created_at
    actions
  end

  filter :commune_departement_code, as: :select, collection: -> { Departement.order(:code).all }
  filter :commune
  filter :palissy_REF_equals
  filter :palissy_TICO
  filter :palissy_CATE
  filter :palissy_EDIF
  filter :palissy_EMPL

  show do
    div class: "show-container" do
      div do
        attributes_table title: "🖼 Objet ##{objet.id}" do
          row :ref_pop
          row :ref_memoire
          row :palissy_TICO
          row :palissy_DENO
          row :commune
          row :palissy_EDIF
          row :palissy_EMPL
          row :palissy_photos_img
          row :palissy_CATE
          row :palissy_SCLE
          row :palissy_DOSS
          row :created_at
        end

        panel "✍️ Recensements" do
          table_for objet.recensements.map(&:decorate) do
            column(:id) { link_to _1.id, admin_old_recensement_path(_1) }
            column :created_at
            column :localisation
            column :edifice_nom
            column :recensable
            column :etat_sanitaire_edifice
            column :etat_sanitaire
            column :securisation
            column :notes_truncated
            column :first_photo_img
          end
        end
      end
      div do
        active_admin_comments
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
