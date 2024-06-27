# Collectif Objets

![CI](https://github.com/adipasquale/collectif-objets/actions/workflows/ci.yml/badge.svg)
&nbsp;&nbsp;[![](https://img.shields.io/badge/Ouvrir%20avec-Gitpod-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/betagouv/collectif-objets/tree/feature/gitpod)

[Collectif Objets est un site web](collectif-objets.beta.gouv.fr/) permettant aux communes françaises de recenser leur patrimoine mobilier monument
historiques et aux conservateurs d'examiner ces recensements.

---

💡 *Toute la documentation est contenue dans ce long README pour être facilement découvrable*

---

<!-- TOC -->
* [Installation](#installation)
* [Découverte du service, captures d'écran, types d’usagers, premiers pas](#découverte-du-service-captures-décran-types-dusagers-premiers-pas)
* [Frameworks et dépendances](#frameworks-et-dépendances)
* [Infrastructure, environnements, écosystème et services externes](#infrastructure-environnements-écosystème-et-services-externes)
* [Diagramme d'entités de la base de données](#diagramme-dentités-de-la-base-de-données)
* [Machines à états finis (*state machines*)](#machines-à-états-finis-state-machines)
* [Code](#code)
  * [Style du code, principes suivis et choix faits](#style-du-code-principes-suivis-et-choix-faits)
  * [Dumps des bases de données](#dumps-des-bases-de-données)
  * [Review apps](#review-apps)
  * [Préparation d'une astreinte dev](#préparation-dune-astreinte-dev)
  * [Données (Origine, Transformations, Republications)](#données-origine-transformations-republications)
  * [Synchronizer : organisation des modules](#synchronizer--organisation-des-modules)
  * [Photos](#photos)
  * [Frontend : Vite, View Components, Stimulus](#frontend--vite-view-components-stimulus)
  * [Intégration du Design Système de l'État Français (DSFR)](#intégration-du-design-système-de-létat-français-dsfr)
  * [Messagerie](#messagerie)
  * [Accessibilité, Plan du site et Pages démos](#accessibilité-plan-du-site-et-pages-démos)
  * [Netlify CMS](#netlify-cms)
  * [Rajouter une vidéo sur le site](#rajouter-une-vidéo-sur-le-site)
  * [Debug local via tunneling](#debug-local-via-tunneling)
  * [Vocabulaire](#vocabulaire)
* [Configurations](#configurations)
  * [Configurations DNS, boites mails, et serveurs mails](#configurations-dns-boites-mails-et-serveurs-mails)
  * [Buckets S3, permissions ACLs et CORS](#buckets-s3-permissions-acls-et-cors)
  * [Configurations des CSP Content Security Policy](#configurations-des-csp-content-security-policy)
<!-- TOC -->

# Installation

**Avec Gitpod** (environnement de développement en ligne configuré automatiquement) : [Ouvrir sur Gitpod ↗️](https://gitpod.io/#https://github.com/betagouv/collectif-objets)

**Avec Docker**: `docker compose up && docker compose run web rails db:setup`

**Sous Mac / Linux**:

- Installer Homebrew : https://brew.sh/

  `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

- Installer rbenv : brew install rbenv ruby-build : https://github.com/rbenv/rbenv

  `brew install rbenv ruby-build`

  `rbenv init`

- Installer Ruby avec rbenv

  ```rbenv install `cat .ruby-version` ```

- Installer Bundler avec la version précisée dans le Gemfile.lock :

  `gem install bundler:2.4.13`

- Installer NodeJS, idéalement la même version qu'en production : https://github.com/nvm-sh/nvm#installing-and-updating

  `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash`

  `nvm install 18`

- Installer Rails et les dépendances

  `make install`

- Lancer le serveur

  `make dev`

- Installer le CLI de Scalingo :

  `curl -O https://cli-dl.scalingo.com/install && bash install`

  Ajouter sa clé SSH dans son compte Scalingo en suivant ces instructions : https://doc.scalingo.com/platform/getting-started/setup-ssh-linux

**Utilisation d'asdf**

Il est possible d'utiliser [asdf](https://asdf-vm.com/guide/getting-started.html) pour installer la bonne version de Ruby et NodeJS. Cela évite d'avoir 2 outils différents (rbenv et nvm ou autres).

Cependant le Makefile n'est pas adapté à son utilisation, il faudrait donc lancer les commandes une à une et préfixer celles avec npm par `asdf exec`

_**optionnel**_: pour une utilisation de rubocop plus rapide en local,
[voir le mode serveur](https://docs.rubocop.org/rubocop/usage/server.html)

**Outils de débogage**

Dans VSCode, installer [l'extension RDBG](https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg) qui permet de déboguer pas à pas directement dans l'IDE.

Il faut d'abord lancer le serveur depuis le terminal dans VSCode (View > Terminal) avec cette commande :
`rdbg -n -c --open=vscode -- bin/rails s`

Puis attacher le débogeur via le menu Run and Debug dans la sidebar. Pour ce faire, éditer le fichier `.vscode/launch.json` pour qu'il ait la configuration suivante :
```
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "rdbg",
            "name": "Attach with rdbg",
            "request": "attach"
        }
    ]
}
```

Vous pourrez ainsi placer des breakpoints depuis VSCode, voir le contenu des variables en les survolant etc.

# Découverte du service, captures d'écran, types d’usagers, premiers pas

Le site expose trois interfaces pour trois types d'usagers différents, toutes accessibles depuis un
site commun unique : https://collectif-objets.beta.gouv.fr

1. **Interface communes**

permet aux agents municipaux des communes de réaliser les recensements d'objets ;

| | |
| - | - |
| ![](doc/interface-communes1.webp) | ![](doc/interface-communes2.webp) |

2. **Interface conservateurs**

permet aux conservateurs d'examiner les recensements réalisés ;

| | |
| - | - |
| ![](doc/interface-conservateurs1.webp) | ![](doc/interface-conservateurs2.webp) |

3. **Interface administrateurs**

permet à l'équipe technique de faire le support

![](doc/interface-admin1.webp)


Découverte de l’interface administrateurs

- [ ] aller sur [localhost:3000/admin](http://localhost:3000/admin)
- [ ] se connecter avec le compte de seed `admin@collectif.local` mot de passe `123456`
- [ ] trouver un lien de connexion magique à une commune dans la Marne 51 et le suivre

Découverte de l’interface communes

- [ ] se connecter depuis un lien magique depuis l'admin (pour info, dans les seeds, le code du lien magique est le code INSEE)
- [ ] recenser un objet en uploadant une photo
- [ ] recenser tous les objets d'une commune et finaliser un dossier

Découverte de l’interface conservateurs

- [ ] se déconnecter en tant que commune
- [ ] se connecter en tant que conservateur depuis le lien de connexion sur le site avec le compte suivant : `conservateur@collectif.local` mot de passe `123456789 123456789 123456789`
- [ ] ouvrir un dossier de recensement à examiner
- [ ] examiner un recensement
- [ ] examiner tous les recensements d'un dossier et l'accepter
- [ ] lire le mail envoyé depuis MailHog sur [localhost:8025](http://localhost:8025)

# Frameworks et dépendances

Les 3 interfaces sont servies par une seule et unique application Ruby On Rails 7.

Les gems principales dont dépend cette application Rails sont :

- `devise` : Authentification des usagers. Il y a trois modèles Devise `User` (Communes), `Conservateur` et `Admin`.
- `pundit` : droits et règles d'accès selon les profils
- `good_job` : Gestion des tâches asynchrones
- `vite_rails` : Compilation des assets JS et images
- `turbo_rails` : Interactions JS simplifiées
- `mjml-rails` : Templates de mails en MJML
- `AASM` : Machines à états finis pour les statuts des modèles
- `haml-rails`, `kramdown` et `view_component` pour les modèles de vues
- `ransack` : recherches et filtres dans l'admin principalement

Côté Javascript les principaux packages utilisés sont :

- `@gouvfr/dsfr` : Design Système de l'État Français
- `@rails/activestorage` : Gestion des uploads de photos
- `@hotwired/stimulus` : Simplifie le lien entre HTML et JS
- `maplibre-gl` : permet d'afficher une carte des communes du département d'un conservateur
- `Chart.js` : diagrammes

# Infrastructure, environnements, écosystème et services externes

```mermaid
flowchart TB

  subgraph ext[Services Externes]
    dashlord
    updown.io
    Mattermost
    Sentry[Sentry Incubateur]
    s3[Scaleway S3 Buckets]
    brevo[Brevo - ex Send In Blue]
    datasette[collectif-objets-datasette.fly.dev]
  end
  subgraph scalingo[Scalingo]
    subgraph rails[Rails App]
      direction TB
      web[Web dynos]
      worker[GoodJob worker dynos]
      cron[Cron tasks]
    end
    rails <--> postgres[(Postgres)]
    postgres -- read-only --> metabase[Metabase]
  end
  subgraph github[GitHub Actions]
    ci[CI\nLint et Tests]
    codeql[CodeQL\nStatic Analysis]
    dependabot[Dependabot]
  end
  rails <--> github
  rails <--> ext
```

3 environnements :

- production : [collectif-objets.beta.gouv.fr](https://collectif-objets.beta.gouv.fr/)
- staging : [staging.collectifobjets.org](https://staging.collectifobjets.org/) - aussi appelé recette ou
  bac à sable - Il n'y a pas de données sensibles sur cette base de données et elle peut être réinitialisée à tout moment. Les emails envoyés par Collectif Objets sont consultables sur [Mailtrap](https://mailtrap.io/).
- local : [localhost:3000](http://localhost:3000) - héberge le site et [localhost:8025](http://localhost:8025) héberge
  MailHog pour voir les emails envoyés par Collectif Objets

Outils & services externes

- [Metabase](https://metabase.collectifobjets.org) - Stats et visualisations
- [Dashboard Scalingo](https://dashboard.scalingo.com/)
- [Sentry de beta.gouv.fr](https://sentry.incubateur.net)
- [Brevo](https://app.brevo.com/) - Campagnes et mails transactionnel
- [Scaleway - buckets S3](https://console.scaleway.com/)
- [Webmail Gandi](https://webmail.gandi.net) - pour les mails en collectifobjets.org
- [Netlify CMS](https://collectif-objets-cms.netlify.app) - pour les fiches et les articles de presse
- [datasette sur fly.io](https://collectif-objets-datasette.fly.dev/)
- [Mailtrap](https://mailtrap.io/) - Pour consulter les emails envoyés depuis les environnements de staging et review apps

# Diagramme d'entités de la base de données

```mermaid
classDiagram

direction RL

class User
User : email

class Commune
Commune : code_insee

class Edifice
Edifice : nom
Edifice : merimee_REF

class Objet
Objet : palissy_REF

class Recensement
Recensement : etat_sanitaire
Recensement : photos

class Dossier
Dossier : status

class Departement
Departement : code

class Campaign
Campaign : date_lancement
Campaign : date_fin

class Conservateur
Conservateur : email

Commune "*" --> "1" Departement
User "*" --> "1" Commune
Edifice "*" --> "1" Commune
Objet "*" --> "1" Edifice
Recensement "*" --> "1" Objet
Recensement "*" --> "0..1" Dossier
Dossier "*" --> "1" Commune
Dossier "*" --> "1" Conservateur : est examiné par
Campaign "*" --> "1" Departement
Commune "*" --> "*" Campaign

```

- Les `User` sont les comptes usagers des communes. C'est un modèle Devise. Un `User` a accès à une et une seule
  commune.
- Les `Conservateurs` sont les comptes usagers des conservateurs. C'est aussi un modèle Devise.
  Un Conservateur a accès à un ou plusieurs départements et toutes les communes inclues.
- Les `Édifices` sont les lieux abritant les objets. Une partie sont des monuments historiques avec des références
  vers la base Mérimée.
- Les `Objets` sont les objets monuments historiques. Leurs infos proviennent de Palissy.
  Leur identifiant unique provient de POP et s'appelle dans notre base `palissy_REF`, il ressemble à `PM00023944`.
- Un `Recensement` contient les observations sur l'état d'un `Objet` et les photos associées à la visite du `User`.
- Un `Dossier` est un ensemble de `Recensements` pour une commune.
  Il doit être finalisé par la commune pour être analysable par les conservateurs.
- Une `Campagne` contient les dates et les communes à démarcher pour une campagne mail avec plusieurs relances.
  Elle est gérée et visible uniquement par les administrateurs.
- Un `AdminUser` est un compte permettant l'accès à l'interface d'admin
Pour créer un nouveau compte, utiliser cette commande dans une console Rails :
```ruby
AdminUser.create(email: "email@de.ladmin", first_name: "Prénom de l'admin", last_name: "Nom de l'admin", password: "mot_de_passe_de_ladmin")
```

La version complète du diagramme d'entités de la base de données est visible ici
[doc/entity-relationship-diagram.svg](doc/entity-relationship-diagram.svg)

# Cycle de vie du recensement d'une commune

Le recensement des objets d'une commune se fait en plusieurs étapes que l'on peut voir sur ce schéma

![cycle de vie dossier drawio](doc/cycle-vie-dossier.drawio.svg)

[éditer](https://app.diagrams.net/#Uhttps%3A%2F%2Fgithub.com%2Fbetagouv%2Fcollectif-objets%2Fraw%2Fmain%2Fdoc%2Fcycle-vie-dossier.drawio.svg)



## Déroulé

1. La commune n'a pas encore recensé d'objets.
2. Suite à une email de campagne ou à une démarche spontanée, la commune recense son premier objet MH. On crée alors le dossier de recensement.
3. La commune a recensé tous ses objets puis cliqué sur "Envoyer le recensement"
4. Si la commune n'a que des objets "verts" (pas dans une situation préoccupante) et que le conservateur n'a pas démarré l'examen, on lui envoie une email en fin de campagne, en précisant que le conservateur ne va pas forcément regarder son dossier en priorité.
5. Le conservateur examine le recensement d'un premier objet.
6. Après avoir examiné tous les objets de la commune, le conservateur clique sur "Accepter le dossier".
7. Si une nouvelle campagne de recensement démarre et que la commune est concernée, la commune repasse en étape 1. On parle de re-recensement. Cette étape peut arriver à tout moment, idéalement après que le conservateur ait examiné le dossier.

## Machines à états finis (*state machines*)

Dans le code, chaque étape modifie l'état de la `Commune`, du `Dossier` ou du `Recensement`.
Il existe aussi la notion de `statut global` sur la commune, qui est affiché en tant que badge pour le conservateur ou dans l'admin. Il est déduit en fonction du statut de la commune, de son dossier et de ses recensements.


| Communes                                   | Recensements                                   | Dossiers                                   | Campaigns                                   |
|--------------------------------------------|------------------------------------------------|--------------------------------------------|---------------------------------------------|
| ![](doc/commune_state_machine_diagram.png) | ![](doc/recensement_state_machine_diagram.png) | ![](doc/dossier_state_machine_diagram.png) | ![](doc/campaign_state_machine_diagram.png) |

`bundle exec rake diagrams:generate[nom_du_model]` permet de mettre à jour ces diagrammes

Ci-dessous les étapes avec le détail des différents statuts en base de données

| Étape | statut global | commune        | recensement(s)                          | dossier                                            |
|-----|-------------|----------------|-----------------------------------------|----------------------------------------------------|
| 1 | Non recensé  | `inactive`     | _aucun recensement_ <br>ou tous `draft` | _aucun dossier_  |
| 2 | En cours de recensement        | `started`      | au moins un `completed`  | `construction` |
| 3 | À examiner en priorité | `completed`    | tous `completed`  | `submitted`|
| 4 | À examiner   | `completed`    | tous `completed` | `submitted`  et `replied_automatically_at` présent |
| 5 | En cours d'examen  | `completed`    | au moins un `completed` et examiné | `submitted` |
| 6 | Examiné  | `completed`    | tous `completed` et tous examinés  | `accepted` |
| 7 | Non recensé  | `inactive`    | _aucun recensement_   | ancien dossier `archived`  |


## Dette technique sur les statuts et le vocabulaire

Le statut global est récupéré à la volée dans une requête SQL plutôt qu'avec un champ dédié. Ce choix a été fait pour déployer les fonctionnalités plus vite, en évitant au maximum de changer l'existant. 

Cependant, il serait judicieux de réduire le nombre de statuts, qui sont d'ailleurs souvent redondants. Nous avions imaginé de supprimer le `status` de la `Commune` et remplacer le `status` du `Dossier` par le `statut_global`. Cela simplifierait grandement le code et améliorerait les performances. En effet, le calcul du `statut_global` peut être lent comparé à lecture d'un champ en base.


Aussi, le mot analysed vient de l'ancien terme "Analysé" et devrait être remplacé par "Examiné". De plus, on pourrait avoir un statut `analysed` ou `examined` sur le recensement, pour que ce soit cohérent avec les statuts `draft` et `completed`.



# Code

## Style du code, principes suivis et choix faits

_Tout ce qui est décrit ci-dessous est évidemment discutable et peut évoluer librement._

Les objectifs principaux de ce code sont :

- permettre d’itérer rapidement ;
- requérir peu de maintenance ;
- être facilement compréhensible, corrigeable et modifiable par d’autres développeur·se·s Rails.

Les commentaires dans le code sont à limiter au minimum, on préfère refactorer le code pour qu’il soit plus clair.

Les contrôleurs sont légers.
Les modèles contiennent la logique métier. Il y a des modèles ActiveRecord et d’autres PORO.
On utilise les concerns pour isoler des comportements de modèles. cf [doctrine 37signals](https://dev.37signals.com/vanilla-rails-is-plenty).
Cela peut évidemment évoluer.

La couverture des tests est modérée.
Il y a des tests E2E pour les chemins les plus importants, principalement pour les cas de succès.
Il y a des tests unitaires pour les modèles quand cela semble nécessaire ou que ça aide l’écriture du code.
Il n’y a pas de tests de contrôleurs, on favorisera les tests E2E ou pas de tests.
Il n’y a pas de tests pour les fonctionnalités natives de Rails ni ActiveRecord.
Les appels ActiveRecord ne sont pas mockés, ils font partie de ce qui est couvert par les tests.

L’ajout de dépendances se fait avec parcimonie, les dépendances transitives sont étudiées à chaque fois.
Cela vaut pour les services tiers, les gems, et les packages JS.

L’introduction de comportements JS custom hors DSFR et Turbo est faite avec parcimonie.
Le site peut en grande partie fonctionner sans JS.
De nombreux usagers sont peu à l’aise avec le numérique, le site doit être aussi standard et sans surprise que possible.
Le site n’est pour l’instant pas tout à fait responsive, c’est une erreur à corriger.

Les règles rubocop basées uniquement sur la longueur des méthodes ou des classes sont volontairement désactivées.
En général il ne faut pas hésiter à désactiver les règles rubocop si on juge qu’elles n’aident pas.

Avec le recul, certains choix méritent d’être revus :

- Le modèle Dossier est peut-être superflu. On pourrait utiliser uniquement le modèle Commune. Aujourd’hui il y a un lien 1:1 dans beaucoup de cas entre ces deux modèles. Il avait été pensé pour permettre à une commune d’ouvrir plusieurs dossiers de recensement mais ce n’est pas le cas aujourd’hui. En année n+5, il est probable qu’on aura déjà supprimé le dossier précédent de notre base de données pour des raisons RGPD.
- Netlify CMS pour le contenu peut être remplacé par des contenus stockés en DB et édités via des textarea ActionText / Trix.
- Le choix de vite pour le build JS est peut–être trop exotique. Il faudrait réévaluer l’usage des importmaps pour éviter tout build system.
- L’utilisation de I18n est à proscrire, ce projet n’a aucune vocation internationale, et l’isolation des contenus dans les fichiers yml ralentit plus qu’elle n’aide. (seule utilité à remplacer : la pluralisation).
- Le mélange de français et d’anglais dans le code et la DB est désagréable. Il faudrait harmoniser les choix, mais la direction à suivre n’est pas encore claire.

## Dumps des bases de données

```sh
# Dans un terminal à part, lancer un tunnel SSH pour avoir accès à la base de données.
# Il faut avoir préalablement configuré une clé SSH dans Scalingo
scalingo --app collectif-objets-staging db-tunnel SCALINGO_POSTGRESQL_URL

# Dans un second terminal, lancer le dump en remplaçant collectif_o_9999 et XXXXX par les données
# de prod ou staging que vous trouverez dans la variable d'environnement SCALINGO_POSTGRESQL_URL.
# Pour récupérer les données de recensement, utiliser plutôt le scritp pg_dump_data_full.sh
./scripts/pg_dump_data_anonymous.sh postgres://collectif_o_9999:XXXXX@localhost:10000/collectif_o_9999 tmp/dump.pgsql

# Le dump peut alors être importé en local
rails db:drop db:create db:schema:load
rails runner scripts/create_postgres_sequences_memoire_photos_numbers.rb
pg_restore --data-only --no-owner --no-privileges --no-comments --dbname=collectif_objets_dev tmp/dump.pgsql
```

Pour mettre à jour le fichier `seeds.pgsql` pour les review apps :

1. Créer et importer un dump de staging (voir section précédente)
2. lancer `rails runner scripts/reset_recensements_dossiers_communes.rb`
3. créer le dump de seeds via `./scripts/pg_dump_data_anonymous.sh collectif_objets_dev tmp/seeds.pgsql`
4. uploader `tmp/seeds.pgsql` sur le bucket S3 `collectif-objets-public`, par exemple avec Cyberduck

en local `rails db:reset` : détruit puis recréé les bases locales, charge le schéma puis les seeds qui se téléchargent
depuis le bucket S3 `collectif-objets-public`.

## Review apps

Les review apps ne sont pas activées automatiquement pour toutes les PRs car elles sont coûteuses en ressources et pas
utiles

```sh
  # Création :
  scalingo integration-link-manual-review-app --app collectif-objets-staging 701

  # Déploiement d’une nouvelle version de la branche
  # git push origin feature/etapes-recensement
  scalingo integration-link-manual-deploy --app collectif-objets-staging-pr701 feature/etapes-recensement && \
  scalingo --app collectif-objets-staging-pr701 deployment-follow

  # Réinitialisation de la base de données
  # on n’a pas les droits pour dropper la db ni l’app
  scalingo --app collectif-objets-staging-pr701 run bash
  rails runner scripts/truncate_all_tables.rb
  rails runner scripts/create_postgres_sequences_memoire_photos_numbers.rb
  rails db:seed
```

Note: Pour faire fonctionner le direct-upload pour les photos sur une review vous devrez rajouter l’hôte de la review dans la liste des hosts autorisés en CORS sur le bucket S3 de staging, voir plus bas.

## Préparation d'une astreinte dev

Voici une liste à suivre pour préparer une astreinte sereine :

- [ ] demander un accès d'administrateur au projet Scalingo. Il faut un compte validé pour accéder à la région osc-secnum-fr1. Une adresse en beta.gouv.fr permet de l'avoir
- [ ] demander un accès contributeur au repository GitHub
- [ ] demander un accès aux projets sur sentry.incubateur.net
- [ ] vérifier que les notifications mail Sentry sont activées
- [ ] activer le 2FA sur GitHub et Sentry
- [ ] demander à être ajouté aux chaînes Mattermost `~projet-collectif_objets` et `~projet-collectif_objets-dev` dans l'espace AtNumCulture
- [ ] se présenter aux membres de l'équipe, déclarer les dates et horaires d'astreinte et les moyens de contact
- [ ] demander un compte admin en prod et en staging
- [ ] faire tourner le projet en local, [cf README/installation](https://github.com/betagouv/collectif-objets/#readme)
- [ ] récupérer la variable d'env RAILS_MASTER_KEY depuis l'app de prod Scalingo (ou un membre de l'équipe) et la définir dans `config/master.key`
- [ ] faire un tour des principales fonctionnalités de l'appli en tant que commune et conservateur

Optionnel :

- [ ] demander un accès Scaleway
- [ ] demander les identifiants partagés de Brevo à l'équipe

## Données (Origine, Transformations, Republications)

```mermaid
flowchart TB

api_service_public[api-lannuaire.service-public.fr]
api_data_culture_gouv[data.culture.gouv.fr]
pop[pop.culture.gouv.fr]
fly[collectif-objets-datasette.fly.dev]

subgraph scraper[pop-scraper - python]
  scraper_run>poetry run scrapy crawl pop_api]
end

subgraph datasette[collectif-objets-datasette - python]
  datasette_run_sqlite>make prepare_sqlite]
  datasette_run_deploy>make deploy]
  csvs[[data_scrapped/*.csv]]
  sqlite[(app/data.sqlite)]
end

subgraph rails[collectif-objets - rails module Synchronizer]
  rails_run_edifices>Edifices::SynchronizeAllJob]
  rails_run_objets>Objets::SynchronizeAllJob]
  rails_run_communes>Communes::SynchronizeAllJob]
  rails_run_photos>Photos::SynchronizeAllJob]
  postgres[(Postgres DB)]
end

pop --> scraper_run
scraper_run --> csvs

csvs --> datasette_run_sqlite
datasette_run_sqlite --> sqlite
sqlite --> datasette_run_deploy
datasette_run_deploy --> fly

api_data_culture_gouv --> rails_run_objets
rails_run_objets --> postgres

api_service_public --> rails_run_communes
rails_run_communes --> postgres

api_data_culture_gouv --> rails_run_edifices
rails_run_edifices --> postgres

fly --> rails_run_photos
rails_run_photos --> postgres

style pop fill:#6666cc
style fly fill:#6666cc
style api_service_public fill:#6666cc
style api_data_culture_gouv fill:#6666cc

style datasette_run_sqlite fill:#888833
style datasette_run_deploy fill:#888833
style rails_run_objets fill:#888833
style rails_run_communes fill:#888833
style rails_run_edifices fill:#888833
style rails_run_photos fill:#888833
style scraper_run fill:#888833
```

Les données sur les communes et les emails des mairies proviennent
de [l’API de service-public.fr](https://api-lannuaire.service-public.fr/explore/dataset/api-lannuaire-administration/api/)

Les données des objets monuments historiques sont récupérées depuis les bases nationales Palissy (objets), Mérimée (édifices) et Mémoire (photos).
Plus d'info sur le processus de synchronisation des données dans [doc/synchronisation.md](doc/synchronisation.md)


La plupart des données stockées sur Collectif Objets sont publiques. Les exceptions sont :

- Les infos personnelles des conservateurs (email, numéro de téléphone)
- Les données de recensements. avant d'être validées et republiées sur POP, elles peuvent contenir des données non-publiques.

## Synchronizer : organisation des modules

Voici un schéma approximatif de l'organisation d’un modules de synchronisation (par exemple `Synchronizer::Objets`) :

```mermaid
graph TD

  SynchronizeAllJob -- instancie des batchs<br> de 1000L --> Batch::Base
  Logger --o SynchronizeAllJob
  Logger --> log>tmp/synchronize.log]
  ApiClient -- itère le CSV --o SynchronizeAllJob
  data[[data.culture.gouv.fr]] -- télécharge CSV --> ApiClient
  Parser -- parse une ligne CSV <br> en attributs AR --o Batch::Base
  EagerLoadStore -- pré-charge les <br> records AR --o Batch::Base
  Batch::Base -- filtre les lignes <br> dans le périmètre de CO --> Row#in_scope?
  Batch::Base -- instancie à partir des attributs <br> parsés et des records préchargés --> Revision#synchronize
  Revision#synchronize -- créé, met à jour, supprime --> db[(DB)]
```

> [!NOTE]
> On détaille ici des aspects techniques du code de ces modules de synchronisation.
> Pour des détails plus haut niveau sur la logique et le périmètre voir [doc/synchronisation.md](doc/synchronisation.md)

Les méthodes `Revision#synchronize` s’appuient autant que possible sur ActiveModel.
On veut faire un appel canonique `objet.save` et que la logique se passe à l’intérieur.
On passe par exemple des [nested attributes](https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html) plutôt que de faire `new_edifice.save! && objet.update(edifice: new_edifice)`.

La classe `Row` est un PORO qui représente une ligne du CSV parsée et sur laquelle on applique des règles de filtrage dans la méthode `#in_scope?`.
Par exemple pour les objets il s’agit de vérifier que la notice Palissy rentre dans le périmètre de Collectif Objets.
On s’appuie ici sur les validations ActiveModel pour avoir une structure commune et des messages d’erreurs compréhensifs.

Il y a un petit point peu agréable dans cette modélisation : `Row` fait un parsing très proche de celui fait dans `Parser` mais légèrement différent.
Par exemple pour les objets on va filtrer sur le champ `palissy_STAT` qu’on ne stocke pas dans les modèles `Objet`.
Il faut donc le parser dans `Row` mais pas dans `Parser`.
Cette modélisation peut être améliorée pour éviter cette redondance.

Le `EagerLoadStore` permet d’éviter les requêtes SQL N+1 en les regroupant au niveau du `Batch`.
C’est un module d’optimisation des performances, il serait plus simple de réécrire le code sans ce préchargement mais cela serait nettement plus long, voire trop long. Il faut bien répercuter les modifications faites par `Revision#synchronize` dans le `EagerLoadStore`.

Exemple :
- les lignes 100 et 101 du batch concernent des objets avec la même référence édifice Mérimée
- cet édifice n’existe pas encore dans notre DB
- la ligne 100 va créer cet édifice
- il faut mettre à jour le `Store` pour que la ligne 101 ne tente pas de recréer cet édifice mais retrouve l’édifice créé par la ligne 100



## Photos

Les métadonnées des photos venant de Mémoire sont stockées dans le champ `objets.palissy_photos` dans un champ JSON, par exemple :

```
[
  {
    "url" : "https://s3.eu-west-3.amazonaws.com/pop-phototeque/memoire/AP01W00056/sap83_01w00056_p.jpg",
    "name" : "vue de la nef",
    "credit" : "© Ministère de la Culture (France), Médiathèque du patrimoine et de la photographie (objets mobiliers), tous droits réservés"
  }
]
```

Les métadonnées des photos mises en ligne par les communes ou les conservateurs lors du recensement sont stockées dans `ActiveStorage::Attachment` et `ActiveStorage::Blob`, liés à l'objet `Recensement`. Les fichiers sont sur un bucket S3.

## Frontend : Vite, View Components, Stimulus

Les fichiers `.rb` des composants View Components sont dans `/app/components`.
Pour chaque composant, tous les fichiers liés (JS, CSS, preview) sont dans un dossier du même nom dans
`/app/components`.

Par exemple un composant GalerieComponent pourra être composé des fichiers suivants :

- `/app/components/galerie_component.rb`
- `/app/components/galerie_component/galerie_component.css`
- `/app/components/galerie_component/lightbox_component_controller.js`
- `/app/components/galerie_component/galerie_component_preview.rb`

Le format du nom du fichier `lightbox_component_controller.js` est important : il ne sera importé que s'il respecte ce format.
Ce fichier doit exporter un controlleur Stimulus et est responsable d'importer le fichier CSS.
La classe de preview doit malheureusement être préfixée par le nom du composant, ici `GalerieComponent::GalerieComponentPreview`.
Cette configuration s'inspire partiellement de [view_component-contrib](https://github.com/palkan/view_component-contrib).

Des controlleurs Stimulus non liés à des composants existent dans :

- `/app/frontend/stimulus_controllers` : importés par défaut dans l'entrypoint `application.js`
- `/app/frontend/stimulus_controllers_standalone` : doivent être importés dans des entrypoints spécifiques

## Intégration du Design Système de l'État Français (DSFR)

L'intégration du DSFR est faite par des liens symboliques définis dans `/public` qui pointent vers les assets
précompilés du package node :

```
/public/dsfr/dsfr.min.css -> /node_modules/@gouvfr/dsfr/dist/dsfr.min.css
/public/dsfr/fonts -> /node_modules/@gouvfr/dsfr/dist/fonts/
/public/dsfr/icons -> /node_modules/@gouvfr/dsfr/dist/icons/
/public/dsfr/utility/utility.min.css -> /../node_modules/@gouvfr/dsfr/dist/utility/utility.min.css
```

Cela permet :
- de ne pas repasser inutilement par un compilateur d'assets (vite dans ce projet)
- de rester à jour avec le DSFR plus facilement en utilisant les upgrades de packages JS

En revanche ce n'est vraiment pas standard et risque de poser des soucis de maintenance.

C'est discuté ici : https://mattermost.incubateur.net/betagouv/pl/ehsuormqztnr3fz6ncuqt9f5ac

## Messagerie

La messagerie permet des échanges entre les usagers, les conservateurs et l'équipe support de Collectif Objets.
Les messages apparaissent dans l'interface de Collectif Objets et sont envoyés par email aux destinataires.
Les conservateurs et usagers peuvent répondre aux emails et les réponses apparaissent dans l'interface de
Collectif Objets.

Pour récupérer ces emails, nous utilisons la fonctionnalité
[Inbound Parsing Webhooks de Brevo](https://developers.brevo.com/docs/inbound-parse-webhooks).
Le script `scripts/create_brevo_webhooks.sh` permet de gérer les webhooks actifs sur Brevo.
Il y a 3 webhooks actifs pour les 3 environnements (production, staging, local) :

```json
[{
  "description": "[STAGING] inbound emails webhook",
  "url": "https://staging.collectifobjets.org/api/v1/inbound_emails",
  "events": ["inboundEmailProcessed"],
  "domain": "reponse-staging.collectifobjets.org"
}, {
  "description": "[PROD] inbound emails webhook",
  "url": "https://collectif-objets.beta.gouv.fr/api/v1/inbound_emails",
  "events": ["inboundEmailProcessed"],
  "domain": "reponse.collectifobjets.org"
}, {
  "description": "Debug inbound email webhook tunneled to localhost",
  "url": "https://collectifobjets-mail-inbound.loophole.site",
  "events": ["inboundEmailProcessed"],
  "domain": "reponse-loophole.collectifobjets.org"
}]
```

Chacun des sous domaines `reponse(-[a-z]+)` de `collectifobjets.org` hébergé sur Gandi est configuré pour rediriger les emails entrants vers Brevo.

Les emails entrants sont reçus sur des adresses signées (qui sont les reply-to des mails de notifications de nouveau
message) qui permettent d'authentifier l'auteur du message :

- `mairie-30001-a1b2c3d4h5@reponse.collectifobjets.org` : réponse de l'usager de la commune 30001 dont le
  `inbound_email_token` secret est `a1b2c3d4h5`.
- `mairie-30001-conservateur-a1b2c3d4h5@reponse.collectifobjets.org` : réponse du conservateur pour la même commune

Voir la partie sur les tunnels plus bas pour itérer en local sur ces webhooks.

## Accessibilité, Plan du site et Pages démos

La démarche d'accessibilité est de réaliser une couverture quasi exhaustive des pages de l'application par des tests
automatisés, puis de faire réaliser des tests manuels dans un second temps.
Actuellement (février 2023) nous sommes à environ 70% de couverture des pages par des tests automatisés.

Les tests automatisés sont réalisés avec [aXe](https://www.deque.com/axe/). Plus d’infos sur https://collectif-objets.beta.gouv.fr/declaration_accessibilite

## Netlify CMS

Netlify CMS est un headless CMS (c'est à dire un backend dissocié de l'application principale) qui permet de modifier
des contenus facilement par des personnes sans modifier le code directement.

Les particularités de ce CMS sont :

- de stocker les contenus dans des fichiers Markdown dans le dépôt Git du projet ;
- de créer des branches et des pull requests pour chaque modification de contenu

Il n'y a donc pas de base de données supplémentaire à gérer ou de serveur d'API de contenu à maintenir, tous les
contenus restent présents dans le dépôt Git.

Nous utilisons ce CMS pour permettre à l'équipe d'éditer les articles de presse, les fiches de conseil et les pages de documentation.

Le CMS est hébergé sur [Netlify](https://www.netlify.com/) et est accessible à l'adresse
[collectif-objets-cms.netlify.app](https://collectif-objets-cms.netlify.app).

Le projet Netlify est configuré pour déployer le répertoire `/cms` à la racine de ce dépôt Git courant.
Le fichier `/cms/config.yml` configure Netlify CMS pour notre cas.
Nous utilisons Netlify Identity pour authentifier les accès au CMS, et un user github robot pour réaliser les commits
et les PRs émanant de Netlify CMS.
Cette configuration est décrite sur [ce pad](https://pad.incubateur.net/zdhV1dI-RBivCfmwXq-hVw#).

⚠️ Après modification de `/cms/config.yml` il faut réactiver les builds sur Netlify.
Ils sont désactivés en temps normal puisque ce fichier est très rarement modifié.

Si l’erreur `Git Gateway Error: Please ask your site administrator to reissue the Git Gateway token` apparaît, il faut
- renouveler le token du user GitHub robot@collectifobjets.org depuis [sur cette page GitHub](https://github.com/settings/tokens) (Settings > Developer settings > Personal Access Tokens (classic)) avec le droit `repo` uniquement
- le copier sur [la configuration Netlify Identity](https://app.netlify.com/sites/collectif-objets-cms/settings/identity) dans Git Gateway

## Rajouter une vidéo sur le site

Télécharger la vidéo au format MP4.
Pour les vidéos Loom il faut avoir un compte, mais pas nécessairement celui du créateur de la vidéo.

Prendre une capture d’écran d’un moment clé de la vidéo à utiliser comme poster.
La convertir en WEBP avec `convert titre.png titre.webm` ou bien la compresser avec imageoptim.

Renommer les fichiers MP4 et PNG/WEBM au format suivant `2023_05_titre_video.mp4`.

Puis convertir en local la vidéo au format WEBM (bien conserver le fichier MP4) :

```bash
ffmpeg -i 2023_05_titre_video.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -b:a 128k -c:a libopus 2023_05_titre_video.webm
```

Compresser le fichier MP4 lui-même s’il est trop lourd :

```bash
ffmpeg -i 2023_05_titre_video.mp4 -vcodec libx265 -crf 30 2023_05_titre_video.mp4
```

💡[Ce gist](https://gist.github.com/adipasquale/af5684a3d70f10a4b59b2d75a002fafa)
contient des scripts pour des raccourcis de conversion dans Mac Os Finder

Uploader les fichiers MP4 et WEBM sur le bucket S3 `collectif-objets-public`.
Donner les permissions ACL en lecture pour tous les visiteurs pour les fichiers uploadés.

Enfin insérer et adapter l’un des deux snippets suivants en HAML ou HTML :

```haml
%video.co-cursor-pointer{controls:"", width:"100%", preload:"none", poster:vite_asset_path("images/2023_05_titre_video.webp"), href:"#"}
  / the href is a fix for a bad rule in DSFR
  %source(src="https://s3.fr-par.scw.cloud/collectif-objets-public/2023_05_titre_video.webm" type="video/webm")
  %source(src="https://s3.fr-par.scw.cloud/collectif-objets-public/2023_05_titre_video.mp4" type="video/mp4")
  %a(href="https://s3.fr-par.scw.cloud/collectif-objets-public/2023_05_titre_video.mp4")
    Télécharger la vidéo au format MP4
```

```html
<video class="co-cursor-pointer" controls="" width="100%" preload="none" poster="https://s3.fr-par.scw.cloud/collectif-objets-public/2023_05_titre_video.png" href="#">
  <source src="https://s3.fr-par.scw.cloud/collectif-objets-public/2023_05_titre_video.webm" type="video/webm">
  <source src="https://s3.fr-par.scw.cloud/collectif-objets-public/2023_05_titre_video.mp4" type="video/mp4">
  <a href="https://s3.fr-par.scw.cloud/collectif-objets-public/2023_05_titre_video.mp4">
    Télécharger la vidéo au format MP4
  </a>
</video>
```


## Debug local via tunneling

Le tunneling consiste à exposer votre environnement local sur une URL publiquement accessible.
`ngrok` est l’outil de tunneling le plus répandu mais nous avons configuré `loophole` sur ce projet car le plan gratuit est plus généreux.
Les instructions d’installation sont sur [le site public de loophole](https://loophole.cloud/).

Une fois installé vous pouvez utiliser :

- `make tunnel` tunnel général du port 3000 accessible sur https://collectifobjets.loophole.site. Cela permet par exemple de tester le rendu sur un mobile.
- `make tunnel_webhooks` expose uniquement l’URL racine https://collectifobjets-mail-inbound.loophole.site qui est configurée sur un webhook inbound parsing sur Brevo.


## Vocabulaire

Un objet dit *prioritaire* est un objet en péril ou disparu. Dans les autres cas, on parle d'*objet vert*.

**Historique**

Le fait d'*examiner* le recensement d'une commune par un conservateur s'appelait précédemment *l'analyse*. De même, on appelait *rapport* la page de synthèse de l'examen.

On retrouve ces termes encore dans le code, il faudrait idéalement les renommer. Attention à bien migrer les champs en base de données contenant le mot "analyse" sur la table recensements, comme par exemple analyse_etat_sanitaire ou analysed_at.

# Configurations

## Configurations DNS, boites mails, et serveurs mails

La configuration des domaines en `.beta.gouv.fr` est gérée par l'équipe transverse de beta.gouv.fr,
idem pour les domaines en `.incubateur.net`

L'adresse `contact@collectif-objets.beta.gouv.fr` est une liste de diffusion beta.gouv.fr, elle se gère depuis le mattermost
de beta cf https://doc.incubateur.net/communaute/travailler-a-beta-gouv/jutilise-les-outils-de-la-communaute/outils/liste-de-diffusion-et-adresses-de-contact#la-commande-mattermost-emails

L'adresse `support@collectif-objets.beta.gouv.fr` est gérée en délégation de service par l'incubateur du ministère de
  la Culture (référent : Ned Baldessin). Idem pour tout le sous-domaine `collectif-objets.beta.gouv.fr`

Le domaine `collectifobjets.org`, le sous domaine de redirection des emails de réponse, et les adresses mails associées
  de l'équipe sont gérées par Adrien et son compte Gandi.

## Buckets S3, permissions ACLs et CORS

Les buckets suivants sont sur Scaleway dans le projet nommé "Collectif objets" :

- `collectif-objets-development2` : photos de recensement et les bordereaux de récolement en PDF ;
- `collectif-objets-staging2` : photos de recensement et les bordereaux de récolement en PDF ;
- `collectif-objets-public` : contenus éditoriaux visibles sur le site (documentation par exemple) et fichier seeds.pgsql ;
- `collectif-objets-private` : pour du stockage en interne

Le bucket le plus important est dans le projet nommé "default" car il y a été créé et ne peut pas être migré facilement :

- `collectif-objets-production` : photos de recensement et les bordereaux de récolement en PDF

Les buckets de photos et bordereaux doivent être configurés pour le CORS

cf https://www.scaleway.com/en/docs/storage/object/api-cli/setting-cors-rules/

```sh
aws s3api put-bucket-cors --bucket collectif-objets-development2 --cors-configuration file://scripts/s3buckets/cors-development.json
aws s3api put-bucket-cors --bucket collectif-objets-staging2 --cors-configuration file://scripts/s3buckets/cors-staging.json
aws s3api put-bucket-cors --bucket collectif-objets-production --cors-configuration file://scripts/s3buckets/cors-production.json
```

Pour configurer l'accès du bucket `collectif-objets-public` utilisez la commande suivante :

`aws s3api put-bucket-policy --bucket collectif-objets-public --policy file://bucket-policy-public.json`

Avec le fichier suivant

```json
{
  "Version": "2022-09-21",
  "Id": "collectifobjets",
  "Statement": [
    {
      "Sid": "Allow public access on all files",
      "Effect": "Allow",
      "Principal": {
        "SCW": "project_id:xxxx-xxxx-xxxx"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "collectif-objets-public"
      ]
    }
  ]
}
```

## Configurations des CSP Content Security Policy

Toute la configuration se trouve dans `config/initializers/content_security_policy.rb`.

Les alertes liées à la CSP peuvent [être filtrées sur Sentry avec `event.type:csp`](https://sentry.incubateur.net/organizations/betagouv/issues/?query=is%3Aunresolved+event.type%3Acsp&referrer=search-bar&sort=date).
Lorsque de nouvelles apparaissent il convient de s’assurer qu’elles proviennent bien de notre code :

- vérifier que le `source_file` de l’évènement n’indique pas quelque chose de suspect comme une extension navigateur
- vérifier que la ressource qui n’a pas pu être chargée est une ressource utilisée dans CO. Par exemple on n’utilise jamais de google fonts, donc une URL en fonts.google bloquée n’est pas un problème de notre code. C’est probablement une extension navigateur aussi
- depuis l’issue, cliquer sur Open in Discover en haut à gauche permet de chercher des points communs entre les occurrences du problème, par exemple des URLs similaires ou bien une famille de navigateurs impactés.

Sentry est déjà configuré pour ignorer les problèmes dont le source_file est `moz_extension` ou `sandbox eval code`, cf [config Sentry](https://sentry.incubateur.net/settings/betagouv/projects/collectif-objets/security-headers/csp/).

Pour débugger les CSPs en local, il peut être utile de désactiver vite dev dans le Procfile.dev et les exceptions spécifiques à l’environnement de dev en haut de `config/initializers/content_security_policy.rb`.

💡 La règle d’or est de tout faire pour ne jamais avoir à rajouter de règle `unsafe inline` pour le style ou pour les scripts.
L’intérêt est en effet que les CSP protègent les usagers d’injections de code.
C'est malheureusement nécessaire pour la prévisualisation des emails, mais :unsafe_inline est autorisé uniquement pour les actions concernées (il est possible de modifier les CSP à la volée par action ou par contrôleur).


