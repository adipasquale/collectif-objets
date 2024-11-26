raise if Rails.configuration.x.environment_specific_name == "production"

path = Rails.root.join("tmp/seeds.pgsql")

def run(command)
  puts "> #{command}"
  `#{command}`
end

puts "downloading seeds file from ..."
run("curl https://s3.fr-par.scw.cloud/collectif-objets-public/seeds.pgsql > #{path}")

db = Rails.configuration.database_configuration[Rails.env]
db_url = db["url"] || "postgresql://#{db["username"]}:#{db["password"]}@#{db["host"]}:#{db["port"]}/#{db["database"]}"

puts "creating postgres sequences not handled by db init (memoire photos)"
run("rails runner scripts/create_postgres_sequences_memoire_photos_numbers.rb")

puts "restoring data to postgres db..."
run("pg_restore --data-only --no-owner --no-privileges --no-comments --dbname=#{db_url} #{path}
")
puts "db restoration done"

Conservateur.create!(email: "conservateur@collectif.local", password: "123456789", departements: Departement.where(code: %w[06 09 12 19 26 51 52 86])) unless Conservateur.where(email: "conservateur@collectif.local").any?
puts "Dev convervateur account created => conservateur@collectif.local mdp 123456789"

AdminUser.create!(email: "admin@collectif.local", password: "123456", first_name: "Test", last_name: "Admin")
puts "Dev admin account created => admin@collectif.local mdp 123456"
