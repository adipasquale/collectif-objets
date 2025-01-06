class AddUserIdToRecensements < ActiveRecord::Migration[7.0]
  def up
    add_reference :recensements, :user, foreign_key: true
    Recensement
      .where(user_id: nil)
      .includes(objet: { commune: [:users]})
      .find_each do |recensement|
        user = recensement.commune.user
        raise "missing user for recensement #{recensement.id} on objet #{recensement.objet.ref_pop}, commune #{recensement.commune.nom} (#{recensement.commune.code_insee})" if user.nil?

        recensement.update_columns(user_id: user.id)
    end
    change_column_null :recensements, :user_id, false
  end

  def down
    remove_reference :recensements, :user, foreign_key: true
  end
end

# Recensement.all.includes(objet: { commune: [:users]}).reject { _1.commune&.users&.present? }.map { "#{_1.objet.commune_nom}"}
