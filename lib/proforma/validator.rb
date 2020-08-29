# frozen_string_literal: true

require 'active_support/core_ext/string'

module Proforma
  class Validator
    def initialize(doc)
      @doc = doc
    end

    def perform
      errors = validate
      raise PreImportValidationError, errors if errors.any?

      errors
    end

    private

    def doc_schema_version
      /^urn:proforma:v(.*)$/.match(@doc.namespaces['xmlns'])[1]
    end

    def validate
      version = doc_schema_version
      return ['version not supported'] unless SCHEMA_VERSIONS.include? version

      Nokogiri::XML::Schema(File.open(SCHEMA_FORMAT_PATH % version)).validate @doc
    end
  end
end
