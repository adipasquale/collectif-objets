class CreateBordereauxAndBordereauxRecensements < ActiveRecord::Migration[7.1]
  def change
    create_table :bordereaux do |t|
      t.belongs_to :dossier, null: false, foreign_key: true, index: true
      t.belongs_to :edifice, null: true, foreign_key: false, index: true
      t.string :edifice_nom, null: false, default: ""

      t.timestamps
    end

    create_table :bordereau_recensements do |t|
      t.belongs_to :bordereau, null: false, foreign_key: true
      t.belongs_to :recensement, null: false, foreign_key: true
      t.string :notes_commune
      t.string :notes_conservateur
      t.string :notes_affectataire
      t.string :notes_proprietaire

      t.timestamps

      t.index [:bordereau_id, :recensement_id], unique: true
    end

    reversible do |direction|
      direction.up do
        say_with_time "Backfill bordereaux and reattach ActiveStorage" do
          bordereaux = backfill_bordereaux
          move_active_storage_from_edifices_to_bordereaux(bordereaux)
          bordereaux.size
        end
      end
      direction.down do
        say_with_time "Reattach ActiveStorage files back to edifices" do
          reattach_active_storage_to_edifices
        end
      end
    end
  end

  def backfill_bordereaux
    data = ActiveRecord::Base.connection.execute(<<-SQL)
      SELECT DISTINCT
        edifices.id AS edifice_id,
        edifices.nom AS edifice_nom,
        dossiers.id AS dossier_id,
        active_storage_attachments.created_at AS created_at
      FROM edifices
      INNER JOIN active_storage_attachments
        ON active_storage_attachments.record_type = 'Edifice'
        AND active_storage_attachments.record_id = edifices.id
        AND active_storage_attachments.name = 'bordereau'
      INNER JOIN communes
        ON communes.code_insee = edifices.code_insee
      INNER JOIN dossiers
        ON dossiers.commune_id = communes.id
        AND dossiers.status != 'archived'
    SQL
    data = data.map do |result|
      {
        edifice_id: result['edifice_id'],
        edifice_nom: result['edifice_nom'].upcase_first,
        dossier_id: result['dossier_id'],
        created_at: result['created_at'],
        updated_at: result['created_at']
      }
    end
    Bordereau.insert_all!(data, returning: [:id, :edifice_id]).rows
  end

  def move_active_storage_from_edifices_to_bordereaux(data)
    return if data.size.zero?

    statements = data.map { |bordereau_id, edifice_id| "WHEN #{edifice_id} THEN #{bordereau_id}" }.join(" ")
    # Reattach bordereaux files stored as ActiveStorage::Attachments from edifice to bordereaux
    ActiveStorage::Attachment.where(record_type: "Edifice", name: :bordereau)
      .update_all(<<-SQL)
        name = 'file',
        record_type = 'Bordereau',
        record_id = CASE record_id #{statements} END
      SQL
  end

  def reattach_active_storage_to_edifices
    ActiveStorage::Attachment.where(record_type: "Bordereau", name: :file)
      .update_all(<<-SQL)
        name = 'bordereau',
        record_type = 'Edifice',
        record_id = (
          SELECT edifice_id
          FROM bordereaux
          WHERE bordereaux.id = active_storage_attachments.record_id
        )
      SQL
  end
end
