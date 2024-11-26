# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_10_28_154819) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.integer "memoire_number"
    t.boolean "exportable", default: true
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_comments", force: :cascade do |t|
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "bordereau_recensements", force: :cascade do |t|
    t.bigint "bordereau_id", null: false
    t.bigint "recensement_id", null: false
    t.string "notes_commune"
    t.string "notes_conservateur"
    t.string "notes_affectataire"
    t.string "notes_proprietaire"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bordereau_id", "recensement_id"], name: "idx_on_bordereau_id_recensement_id_205ed59768", unique: true
    t.index ["bordereau_id"], name: "index_bordereau_recensements_on_bordereau_id"
    t.index ["recensement_id"], name: "index_bordereau_recensements_on_recensement_id"
  end

  create_table "bordereaux", force: :cascade do |t|
    t.bigint "dossier_id", null: false
    t.bigint "edifice_id"
    t.string "edifice_nom", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dossier_id"], name: "index_bordereaux_on_dossier_id"
    t.index ["edifice_id"], name: "index_bordereaux_on_edifice_id"
  end

  create_table "campaign_emails", force: :cascade do |t|
    t.bigint "campaign_recipient_id"
    t.string "step"
    t.string "sib_message_id"
    t.boolean "sent"
    t.boolean "delivered"
    t.boolean "opened"
    t.boolean "clicked"
    t.string "error"
    t.string "error_reason"
    t.string "subject"
    t.json "headers"
    t.json "sib_events"
    t.datetime "last_sib_synchronization_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email_name"
    t.index ["campaign_recipient_id"], name: "index_campaign_emails_on_campaign_recipient_id"
  end

  create_table "campaign_recipients", force: :cascade do |t|
    t.bigint "campaign_id"
    t.bigint "commune_id"
    t.string "current_step"
    t.boolean "opt_out", default: false
    t.string "opt_out_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unsubscribe_token"
    t.index ["campaign_id", "commune_id"], name: "index_campaign_recipients_on_campaign_id_and_commune_id", unique: true
    t.index ["campaign_id"], name: "index_campaign_recipients_on_campaign_id"
    t.index ["commune_id"], name: "index_campaign_recipients_on_commune_id"
    t.index ["unsubscribe_token"], name: "index_campaign_recipients_on_unsubscribe_token", unique: true
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "status", default: "draft", null: false
    t.string "departement_code", null: false
    t.date "date_lancement"
    t.date "date_relance1"
    t.date "date_relance2"
    t.date "date_relance3"
    t.date "date_fin"
    t.string "sender_name"
    t.string "signature"
    t.string "nom_drac"
    t.boolean "imported", default: false
    t.json "stats"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "custom_message"
    t.integer "recipients_count", default: 0
    t.index ["departement_code"], name: "index_campaigns_on_departement_code"
  end

  create_table "communes", force: :cascade do |t|
    t.string "nom"
    t.string "code_insee"
    t.string "departement_code"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "inactive", null: false
    t.datetime "completed_at"
    t.datetime "started_at"
    t.float "latitude"
    t.float "longitude"
    t.string "inbound_email_token", null: false
    t.datetime "last_in_scope_at"
    t.integer "objets_count", default: 0, null: false
    t.index ["code_insee"], name: "communess_unique_code_insee", unique: true
    t.index ["departement_code"], name: "index_communes_on_departement_code"
  end

  create_table "conservateur_roles", force: :cascade do |t|
    t.bigint "conservateur_id"
    t.string "departement_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conservateur_id"], name: "index_conservateur_roles_on_conservateur_id"
    t.index ["departement_code"], name: "index_conservateur_roles_on_departement_code"
  end

  create_table "conservateurs", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.datetime "last_sign_in_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "messages_mail_notifications", default: true
    t.boolean "send_recap", default: false, null: false
    t.index ["email"], name: "index_conservateurs_on_email", unique: true
  end

  create_table "departements", primary_key: "code", id: :string, force: :cascade do |t|
    t.string "nom", null: false
    t.string "service_public_prefix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dans_nom"
    t.boolean "concordataire"
    t.string "bounding_box", default: [], null: false, array: true
    t.integer "communes_count", default: 0, null: false
    t.string "region"
  end

  create_table "dossiers", force: :cascade do |t|
    t.bigint "commune_id", null: false
    t.string "status", default: "construction", null: false
    t.datetime "submitted_at"
    t.datetime "accepted_at"
    t.string "notes_commune"
    t.string "notes_conservateur"
    t.bigint "conservateur_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "visit"
    t.datetime "replied_automatically_at"
    t.datetime "archived_at"
    t.text "recenseur"
    t.bigint "campaign_id"
    t.index ["campaign_id"], name: "index_dossiers_on_campaign_id"
    t.index ["commune_id"], name: "index_dossiers_on_commune_id"
    t.index ["conservateur_id"], name: "index_dossiers_on_conservateur_id"
    t.index ["status"], name: "index_dossiers_on_status", using: :hash
  end

  create_table "edifices", force: :cascade do |t|
    t.string "merimee_REF"
    t.string "code_insee"
    t.string "nom"
    t.string "merimee_PRODUCTEUR"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code_insee"], name: "index_edifices_on_code_insee"
    t.index ["merimee_REF"], name: "index_edifices_on_merimee_REF"
  end

  create_table "good_job_batches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.jsonb "serialized_properties"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_discard"
    t.text "callback_queue_name"
    t.integer "callback_priority"
    t.datetime "enqueued_at"
    t.datetime "discarded_at"
    t.datetime "finished_at"
  end

  create_table "good_job_executions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id", null: false
    t.text "job_class"
    t.text "queue_name"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.text "error"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_job_executions_on_active_job_id_and_created_at"
  end

  create_table "good_job_processes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "state"
  end

  create_table "good_job_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "key"
    t.jsonb "value"
    t.index ["key"], name: "index_good_job_settings_on_key", unique: true
  end

  create_table "good_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "queue_name"
    t.integer "priority"
    t.jsonb "serialized_params"
    t.datetime "scheduled_at"
    t.datetime "performed_at"
    t.datetime "finished_at"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "active_job_id"
    t.text "concurrency_key"
    t.text "cron_key"
    t.uuid "retried_good_job_id"
    t.datetime "cron_at"
    t.uuid "batch_id"
    t.uuid "batch_callback_id"
    t.boolean "is_discrete"
    t.integer "executions_count"
    t.text "job_class"
    t.integer "error_event", limit: 2
    t.index ["active_job_id", "created_at"], name: "index_good_jobs_on_active_job_id_and_created_at"
    t.index ["active_job_id"], name: "index_good_jobs_on_active_job_id"
    t.index ["batch_callback_id"], name: "index_good_jobs_on_batch_callback_id", where: "(batch_callback_id IS NOT NULL)"
    t.index ["batch_id"], name: "index_good_jobs_on_batch_id", where: "(batch_id IS NOT NULL)"
    t.index ["concurrency_key"], name: "index_good_jobs_on_concurrency_key_when_unfinished", where: "(finished_at IS NULL)"
    t.index ["cron_key", "created_at"], name: "index_good_jobs_on_cron_key_and_created_at_cond", where: "(cron_key IS NOT NULL)"
    t.index ["cron_key", "cron_at"], name: "index_good_jobs_on_cron_key_and_cron_at_cond", unique: true, where: "(cron_key IS NOT NULL)"
    t.index ["finished_at"], name: "index_good_jobs_jobs_on_finished_at", where: "((retried_good_job_id IS NULL) AND (finished_at IS NOT NULL))"
    t.index ["priority", "created_at"], name: "index_good_jobs_jobs_on_priority_created_at_when_unfinished", order: { priority: "DESC NULLS LAST" }, where: "(finished_at IS NULL)"
    t.index ["queue_name", "scheduled_at"], name: "index_good_jobs_on_queue_name_and_scheduled_at", where: "(finished_at IS NULL)"
    t.index ["scheduled_at"], name: "index_good_jobs_on_scheduled_at", where: "(finished_at IS NULL)"
  end

  create_table "inbound_emails", id: :string, force: :cascade do |t|
    t.string "body_html"
    t.string "body_text"
    t.string "body_md"
    t.string "signature_md"
    t.string "from_email"
    t.string "to_email"
    t.string "sent_at"
    t.json "raw"
  end

  create_table "messages", force: :cascade do |t|
    t.string "origin"
    t.bigint "commune_id", null: false
    t.string "inbound_email_id"
    t.bigint "author_id"
    t.string "author_type"
    t.string "text"
    t.string "automated_mail_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commune_id"], name: "index_messages_on_commune_id"
  end

  create_table "objets", force: :cascade do |t|
    t.string "palissy_REF"
    t.string "memoire_REF"
    t.string "palissy_DENO"
    t.string "palissy_CATE"
    t.string "palissy_COM"
    t.string "palissy_INSEE"
    t.string "palissy_DPT"
    t.string "palissy_SCLE"
    t.string "palissy_DENQ"
    t.string "palissy_DOSS"
    t.string "palissy_EDIF"
    t.string "palissy_EMPL"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "palissy_TICO"
    t.json "palissy_photos", default: [], array: true
    t.string "palissy_REFA"
    t.bigint "edifice_id"
    t.string "palissy_PROT"
    t.string "palissy_DPRO"
    t.string "palissy_DEPL"
    t.string "palissy_WEB"
    t.string "palissy_MOSA"
    t.string "lieu_actuel_code_insee"
    t.string "lieu_actuel_edifice_nom"
    t.string "lieu_actuel_edifice_ref"
    t.string "lieu_actuel_departement_code"
    t.index ["edifice_id"], name: "index_objets_on_edifice_id"
    t.index ["lieu_actuel_code_insee"], name: "index_objets_on_lieu_actuel_code_insee"
    t.index ["lieu_actuel_departement_code"], name: "index_objets_on_lieu_actuel_departement_code"
    t.index ["palissy_COM"], name: "index_objets_on_palissy_COM"
    t.index ["palissy_DPT"], name: "index_objets_on_palissy_DPT"
    t.index ["palissy_INSEE"], name: "index_objets_on_palissy_INSEE"
    t.index ["palissy_REF"], name: "objets_unique_ref_pop", unique: true
  end

  create_table "pop_exports", force: :cascade do |t|
    t.string "base", null: false
    t.string "departement_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recensements", force: :cascade do |t|
    t.bigint "objet_id"
    t.string "localisation"
    t.boolean "recensable"
    t.string "edifice_nom"
    t.string "etat_sanitaire"
    t.string "securisation"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "analyse_etat_sanitaire"
    t.string "analyse_etat_sanitaire_edifice"
    t.string "analyse_securisation"
    t.string "analyse_fiches", default: [], array: true
    t.text "analyse_notes"
    t.datetime "analysed_at"
    t.bigint "conservateur_id"
    t.bigint "dossier_id"
    t.bigint "pop_export_memoire_id"
    t.bigint "pop_export_palissy_id"
    t.string "status", default: "draft", null: false
    t.integer "photos_count", default: 0
    t.datetime "deleted_at"
    t.string "deleted_reason"
    t.string "deleted_message"
    t.jsonb "deleted_objet_snapshot"
    t.string "autre_commune_code_insee"
    t.index ["conservateur_id"], name: "index_recensements_on_conservateur_id"
    t.index ["deleted_at"], name: "index_recensements_on_deleted_at"
    t.index ["dossier_id"], name: "index_recensements_on_dossier_id"
    t.index ["objet_id", "dossier_id"], name: "index_recensements_on_objet_id_and_dossier_id", unique: true
  end

  create_table "session_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "code"
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_session_codes_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_session_codes_on_user_id"
  end

  create_table "survey_votes", force: :cascade do |t|
    t.bigint "commune_id"
    t.string "survey"
    t.string "reason"
    t.string "additional_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commune_id", "survey"], name: "index_survey_votes_on_commune_id_and_survey", unique: true
    t.index ["commune_id"], name: "index_survey_votes_on_commune_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "last_sign_in_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "commune_id"
    t.string "magic_token_deprecated"
    t.string "nom"
    t.string "job_title"
    t.string "email_personal"
    t.string "phone_number"
    t.boolean "messages_mail_notifications", default: true
    t.index ["commune_id"], name: "index_users_on_commune_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["magic_token_deprecated"], name: "index_users_on_magic_token_deprecated", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bordereau_recensements", "bordereaux"
  add_foreign_key "bordereau_recensements", "recensements"
  add_foreign_key "bordereaux", "dossiers"
  add_foreign_key "dossiers", "campaigns"
  add_foreign_key "dossiers", "communes"
  add_foreign_key "messages", "communes"
  add_foreign_key "recensements", "objets"
  add_foreign_key "session_codes", "users"
  add_foreign_key "users", "communes"
end
