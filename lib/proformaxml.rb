# frozen_string_literal: true

require 'active_model'
require 'nokogiri'
require 'zip'
require 'base64'
require 'securerandom'
require 'dachsfisch'

require 'proformaxml/version'

require 'proformaxml/services/importer'
require 'proformaxml/services/exporter'
require 'proformaxml/services/validator'
require 'proformaxml/services/version_and_namespace_extractor'
require 'proformaxml/models/task'

module ProformaXML
  SCHEMA_PATH = File.join(File.dirname(File.expand_path(__FILE__)), '../assets/schemas')
  SCHEMA_FORMAT_PATH = "#{SCHEMA_PATH}/proforma-%s.xsd".freeze
  SCHEMA_VERSIONS = %w[2.1 2.0].freeze

  TEST_TYPE_SCHEMA_NAMES = %w[java-checkstyle regexptest unittest].freeze
  MAX_EMBEDDED_FILE_SIZE_KB = 50
end
