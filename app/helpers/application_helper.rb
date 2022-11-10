# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def head_title
    if content_for(:head_title).present?
      "#{content_for(:head_title)} · Collectif Objets"
    else
      "Collectif Objets"
    end
  end

  def badge(color = "", **html_opts)
    html_opts[:class] ||= ""
    html_opts[:class] += " fr-badge fr-badge--sm fr-badge--#{color}"
    content_tag("p", yield, **html_opts)
  end

  def link_to_button(content, path, **kwargs)
    content_tag("form", method: "GET", action: path) do
      content_tag("button", **kwargs) { content }
    end
  end

  def blockquote(content, html_options = {})
    html_options = html_options.with_indifferent_access
    html_options[:class] ||= ""
    html_options[:class] += " fr-callout__text co-blockquote fr-text--alt"
    content_tag("blockquote", content, **html_options)
  end

  def t_fallback(key)
    return I18n.t(key) if I18n.exists?(key)

    scope = key.split(".").tap(&:pop).join(".")
    I18n.t("#{scope}.other")
  end

  def vite_or_raw_image_tag(src, **kwargs)
    return vite_image_tag(src, **kwargs) if src.is_a?(String) && src.start_with?("images/")

    image_tag(src, **kwargs)
  end

  # rubocop:disable Rails/OutputSafety
  def inline_svg(path)
    path = path[1..] if path[0].start_with? "/"
    file_path = Rails.root.join(path)
    if File.exist?(file_path)
      Rails.cache.fetch("inline-svg-#{path}", expires_in: 24.hours) do
        File.read(file_path).html_safe
      end
    else
      "(not found)"
    end
  end
  # rubocop:enable Rails/OutputSafety
end
