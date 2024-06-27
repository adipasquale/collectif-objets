# frozen_string_literal: true

require_relative "boot"

require "rails"
require "good_job/engine"

# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "rails/test_unit/railtie"
require "dsfr/components"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CollectifObjets
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Europe/Paris"

    config.autoload_lib(ignore: %w[assets tasks])

    config.action_dispatch.cookies_same_site_protection = :strict

    config.action_mailer.preview_paths << Rails.root.join("lib/mailer_previews")

    config.active_job.queue_adapter = :good_job

    config.x.inbound_emails_domain = "test.domain.fr"

    config.view_component.default_preview_layout = "component_preview"

    config.action_controller.raise_on_missing_callback_actions = false

    config.i18n.raise_on_missing_translations = true
  end
end
