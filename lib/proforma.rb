# frozen_string_literal: true

require 'proforma/version'
require 'proforma/importer'
require 'proforma/task'

module Proforma
  XML_NAMESPACE = 'urn:proforma:v2.0.1'
  SCHEMA_PATH = 'assets/schemas/proforma.xsd'

  class Error < StandardError; end
  # Your code goes here...
end
