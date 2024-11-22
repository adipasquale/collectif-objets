# frozen_string_literal: true

class MattermostApiError < StandardError; end

class SendMattermostNotificationJob < ApplicationJob
  # The extension must be included before other extensions
  include GoodJob::ActiveJobExtensions::InterruptErrors
  # Discard the job if it is interrupted
  # This avoids having jobs that are in the Running queue indefinitely
  discard_on GoodJob::InterruptError

  HOOKS_URL = "https://mattermost.incubateur.net/hooks/#{Rails.application.credentials.mattermost&.hook_id}".freeze
  HANDLED_EVENTS = %w[commune_completed recensement_created dossier_auto_submitted message_created].freeze

  def perform(event, payload)
    raise "unsupported event type #{event}" unless HANDLED_EVENTS.include?(event)

    @event = event.to_sym
    @payload = payload.with_indifferent_access
    return send_notification if Rails.configuration.x.environment_specific_name == "production"

    GoodJob.logger.info { "would have sent mattermost notification #{body}" }
  end

  protected

  def send_notification
    headers = { "Content-Type" => "application/json" }
    res = Typhoeus.post(HOOKS_URL, headers:, body:)
    raise MattermostApiError, "status: #{res.response_code}" unless res.success?
  end

  def body
    { text: message, attachments:, icon_emoji:, channel: }.compact.to_json
  end

  def notification
    @notification ||= notification_class_name.constantize.new(@payload)
  end

  delegate :message, :attachments, :icon_emoji, :channel, to: :notification

  def notification_class_name
    "Co::AdminNotifications::#{ActiveSupport::Inflector.classify(@event)}Notification"
  end
end
