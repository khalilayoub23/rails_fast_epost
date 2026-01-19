# frozen_string_literal: true

require "yaml"
require "minitest/autorun"

class I18nKeysTest < Minitest::Test
  LOCALES = %w[en he ru ar].freeze
  LOCALES_PATH = File.expand_path("../config/locales", __dir__)

  # Namespaces that we don't require to be mirrored across locales (third-party)
  IGNORED_TOP_LEVEL = %w[devise simple_form].freeze
  # Keys that are allowed to differ per locale (metadata/demo)
  IGNORED_FULL_KEYS = [
    "hello", # demo key
    "language_name",
    "direction"
  ].freeze

  def test_locales_have_consistent_keys
    locale_maps = LOCALES.to_h { |lc| [ lc, load_locale(lc) ] }

    union_keys = locale_maps.values.flat_map { |h| flatten_keys(h) }.uniq

    LOCALES.each do |lc|
      missing = union_keys - flatten_keys(locale_maps[lc])
      missing.reject! { |k| ignored_key?(k) }
      assert missing.empty?, "#{lc} is missing keys: #{missing.sort.join(", ")}"
    end
  end

  private

  def load_locale(lc)
    file = File.join(LOCALES_PATH, "#{lc}.yml")
    doc  = YAML.safe_load(File.read(file))
    doc.fetch(lc)
  end

  def flatten_keys(hash, prefix = [])
    hash.flat_map do |k, v|
      key = (prefix + [ k.to_s ]).join(".")
      if v.is_a?(Hash)
        flatten_keys(v, prefix + [ k.to_s ])
      else
        key
      end
    end
  end

  def ignored_key?(key)
    top = key.split(".").first
    return true if IGNORED_TOP_LEVEL.include?(top)

    IGNORED_FULL_KEYS.any? { |s| key.end_with?(".#{s}") || key == s }
  end
end
