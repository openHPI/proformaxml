# frozen_string_literal: true

require 'active_model'
require 'nokogiri'
require 'zip'
require 'base64'
require 'securerandom'
require 'dachsfisch'

require 'proforma/version'

require 'proforma/services/importer'
require 'proforma/services/exporter'
require 'proforma/services/validator'
require 'proforma/models/task'

module Proforma
  SCHEMA_PATH = File.join(File.dirname(File.expand_path(__FILE__)), '../assets/schemas')
  SCHEMA_FORMAT_PATH = "#{SCHEMA_PATH}/proforma-%s.xsd".freeze
  SCHEMA_VERSIONS = %w[2.1 2.0].freeze

  TEST_TYPE_SCHEMA_NAMES = %w[checkstyle regexptest unittest].freeze
  TEST_TYPE_SCHEMAS = {}.tap do |hash|
    TEST_TYPE_SCHEMA_NAMES.each do |name|
      path = SCHEMA_FORMAT_PATH % name
      namespace = Nokogiri::XML(File.read(path)).xpath('xs:schema').first&.attributes&.dig('targetNamespace')&.value
      hash[namespace] = name
    end
  end
  MAX_EMBEDDED_FILE_SIZE_KB = 50
end
