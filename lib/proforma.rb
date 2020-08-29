# frozen_string_literal: true

require 'active_model'
require 'nokogiri'
require 'zip'
require 'base64'
require 'securerandom'

require 'proforma/version'

require 'proforma/importer'
require 'proforma/exporter'
require 'proforma/validator'
require 'proforma/task'

module Proforma
  XML_NAMESPACE = 'urn:proforma:v2.0.1'
  SCHEMA_FORMAT_PATH = File.join(File.dirname(File.expand_path(__FILE__)), '../assets/schemas/proforma_%s.xsd')
  SCHEMA_VERSIONS = ['2.0.1', '2.0'].freeze
  MAX_EMBEDDED_FILE_SIZE_KB = 50
  class Error < StandardError; end
end
