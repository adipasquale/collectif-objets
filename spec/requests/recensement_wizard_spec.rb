# frozen_string_literal: true

require "rails_helper"

RSpec.describe Communes::RecensementsController, type: :request do
  let(:commune) { create(:commune, :with_user) }
  let(:objet) { create(:objet, commune:) }
  let(:user) { commune.user }
  let(:params) { {} }

  before(:each) { login_as(user, scope: :user) }

  subject(:perform_request) { send(method, path, params:) }

  context "POST communes/1/objets/1/recensements" do
    let(:method) { :post }
    let(:path) { commune_objet_recensements_path(commune_id: commune.id, objet_id: objet.id) }

    context "si l'objet n'a pas de recensement" do
      let(:recensement) { objet.recensements.last }
      it "crée un nouveau recensement" do
        expect { perform_request }.to change(Recensement, :count).by(1)
        expect(recensement.draft?).to eq true
      end
    end
    context "quand l'utilisateur n'appartient pas à la commune" do
      # Rediriger vers le login semblerait plus logique, non ?
      it "redirige vers la page d'accueil" do
        user = create(:user)
        login_as(user, scope: :user)
        expect { perform_request }.to change(Recensement, :count).by(0)
        expect(response).to redirect_to root_path
      end
    end
    context "quand l'objet a déjà un recensement" do
      # Si un recensement existe, l'autorisation est refusée. Rediriger vers le recensement en cours plutôt ?
      it "redirige vers la page d'accueil" do
        commune.start
        create(:recensement, objet:, dossier: commune.dossier)
        expect { perform_request }.to change(Recensement, :count).by(0)
        expect(response).to redirect_to root_path
      end
    end
  end

  context "PATCH communes/1/objets/1/recensements/1&step=" do
    before { commune.start! }
    let(:recensement) { create(:recensement, objet:, status: :draft, dossier: commune.dossier) }
    let(:path) { commune_objet_recensement_path(commune_id: commune.id, objet_id: objet.id, id: recensement.id, step:) }
    let(:method) { :patch }
    let(:next_step) do
      edit_commune_objet_recensement_path(commune_id: commune.id, objet_id: objet.id, id: recensement.id,
                                          step: next_step_number)
    end

    context "Étape 1" do
      let(:step) { 1 }
      let(:params) { { wizard: { localisation: } } }
      context "si l'objet se trouve dans l'édifice" do
        let(:localisation) { Recensement::LOCALISATION_EDIFICE_INITIAL }
        let(:next_step_number) { 3 }
        it "enregistre et redirige vers l'étape 3" do
          perform_request
          expect(recensement.reload.localisation).to eq localisation
          expect(response).to redirect_to next_step
        end
      end
      context "si l'objet se trouve dans un autre édifice" do
        let(:localisation) { Recensement::LOCALISATION_AUTRE_EDIFICE }
        let(:next_step_number) { 2 }
        it "enregistre et redirige vers l'étape 2" do
          perform_request
          expect(recensement.reload.localisation).to eq localisation
          expect(response).to redirect_to next_step
        end
      end
      context "si l'objet se trouve dans une autre commune" do
        let(:localisation) { Recensement::LOCALISATION_DEPLACEMENT_AUTRE_COMMUNE }
        let(:next_step_number) { 2 }
        it "enregistre et redirige vers l'étape 2" do
          perform_request
          expect(recensement.reload.localisation).to eq localisation
          expect(response).to redirect_to next_step
        end
      end
      context "si l'objet est temporairement déplacé" do
        let(:localisation) { Recensement::LOCALISATION_DEPLACEMENT_TEMPORAIRE }
        let(:next_step_number) { 6 }
        it "enregistre et redirige vers l'étape 6" do
          perform_request
          expect(recensement.reload.localisation).to eq localisation
          expect(response).to redirect_to next_step
        end
      end
      context "si l'objet est introuvable" do
        let(:localisation) { Recensement::LOCALISATION_ABSENT }
        let(:next_step_number) { 6 }
        it "enregistre et redirige vers l'étape 6" do
          perform_request
          expect(recensement.reload.localisation).to eq localisation
          expect(response).to redirect_to next_step
        end
      end
    end

    context "Étape 2" do
      let(:step) { 2 }
      context "si l'objet se trouve dans un édifice existant" do
        let(:edifice_nom_existant) { create(:edifice, commune:).nom }
        let(:params) { { wizard: { edifice_nom_existant: } } }
        let(:next_step_number) { 3 }
        it "enregistre et redirige vers l'étape 3" do
          perform_request
          expect(recensement.reload.edifice_nom).to eq edifice_nom_existant
          expect(response).to redirect_to next_step
        end
      end
      context "si l'objet se trouve dans un édifice non listé" do
        let(:params) { { wizard: { edifice_nom_existant: "0", edifice_nom: "Édifice non listé" } } }
        let(:next_step_number) { 3 }
        it "enregistre et redirige vers l'étape 3" do
          perform_request
          expect(recensement.reload.edifice_nom).to eq "Édifice non listé"
          expect(response).to redirect_to next_step
        end
      end
      context "si l'objet se trouve dans une autre commune" do
        let(:autre_commune_code_insee) { create(:commune).code_insee }
        let(:params) { { wizard: { autre_commune_code_insee:, edifice_nom: "Édifice d'une autre commune" } } }
        let(:next_step_number) { 3 }
        it "enregistre et redirige vers l'étape 3" do
          perform_request
          expect(recensement.reload.autre_commune_code_insee).to eq autre_commune_code_insee
          expect(recensement.edifice_nom).to eq "Édifice d'une autre commune"
          expect(response).to redirect_to next_step
        end
      end
    end

    context "Étape 3" do
      let(:step) { 3 }
      context "si l'objet est recensable" do
        let(:params) { { wizard: { recensable: true } } }
        let(:next_step_number) { 4 }
        it "enregistre et redirige vers l'étape 4" do
          perform_request
          expect(recensement.reload.recensable).to eq true
          expect(response).to redirect_to next_step
        end
      end
      context "si l'objet n'est pas recensable" do
        let(:params) { { wizard: { recensable: false } } }
        let(:next_step_number) { 6 }
        it "enregistre et redirige vers l'étape 6" do
          perform_request
          expect(recensement.reload.recensable).to eq false
          expect(response).to redirect_to next_step
        end
      end
    end

    context "Étape 4" do
      let(:step) { 4 }
      context "si aucune photo n'est fournie" do
        let(:params) { { wizard: { confirmation_no_photos: true } } }
        let(:next_step_number) { 5 }
        it "enregistre et redirige vers l'étape 5" do
          perform_request
          expect(response).to redirect_to next_step
        end
      end
    end

    context "Étape 5" do
      let(:step) { 5 }
      context "si l'objet est en bon état et en sécurité" do
        let(:params) do
          { wizard: { etat_sanitaire: Recensement::ETAT_BON, securisation: Recensement::SECURISATION_CORRECTE } }
        end
        let(:next_step_number) { 6 }
        it "enregistre et redirige vers l'étape 6" do
          perform_request
          expect(recensement.reload.etat_sanitaire).to eq Recensement::ETAT_BON
          expect(recensement.securisation).to eq Recensement::SECURISATION_CORRECTE
          expect(response).to redirect_to next_step
        end
      end
      context "si l'état et la sécurisation de l'objet ne sont pas indiqués" do
        let(:params) { { wizard: { etat_sanitaire: "", securisation: "" } } }
        let(:next_step_number) { 5 }
        it "affiche un message d'erreur" do
          perform_request
          expect(response).to have_http_status :unprocessable_content
        end
      end
    end

    context "Étape 6" do
      let(:step) { 6 }
      context "si des notes sont fournies" do
        let(:params) { { wizard: { notes: "Notes" } } }
        let(:next_step_number) { 7 }
        it "enregistre et redirige vers l'étape 7" do
          perform_request
          expect(recensement.reload.notes).to eq "Notes"
          expect(response).to redirect_to next_step
        end
      end
      context "si le champ notes reste vide" do
        let(:params) { { wizard: { notes: "" } } }
        let(:next_step_number) { 7 }
        it "enregistre et redirige vers l'étape 7" do
          perform_request
          expect(recensement.reload.notes).to eq ""
          expect(response).to redirect_to next_step
        end
      end
    end

    context "Étape 7" do
      let(:step) { 7 }
      context "si le recensement est valide" do
        it "clôture le recensement" do
          perform_request
          expect(recensement.reload.completed?).to eq true
          expect(response).to redirect_to commune_objets_path(commune, objet_id: objet.id, recensement_saved: true)
        end
      end
      context "si le recensement est déjà completed" do
        it "redirige sans erreur" do
          recensement.complete!
          perform_request
          expect(recensement.reload.completed?).to eq true
          expect(response).to redirect_to commune_objets_path(commune, objet_id: objet.id, recensement_saved: true)
        end
      end
      context "si le recensement est invalide" do
        it "affiche un message d'erreur" do
          # Met le recensement dans un état invalide sans passer par les validations
          recensement.update_columns(status: :completed, autre_commune_code_insee: nil,
                                     localisation: Recensement::LOCALISATION_DEPLACEMENT_AUTRE_COMMUNE)
          perform_request
          expect(response).to have_http_status :unprocessable_content
        end
      end
    end
  end

  context "DELETE communes/1/objets/1/recensements/1" do
    before { commune.start! }
    let(:recensement) { create(:recensement, objet:, status: :completed, dossier: commune.dossier) }
    let(:method) { :delete }
    let(:path) { commune_objet_recensement_path(commune_id: commune.id, objet_id: objet.id, id: recensement.id) }

    context "si le recensement peut être supprimé" do
      it "supprime le recensement" do
        recensement
        expect { perform_request }.to change(Recensement, :count).by(-1)
      end
    end
  end
end
