# frozen_string_literal: true

require 'active_support/core_ext/string'

module Proforma
  class Validator
    def initialize(doc, expected_version = nil)
      @doc = doc
      @expected_version = expected_version
    end

    def perform
      validate
    end

    private

    def doc_schema_version
      /^urn:proforma:v(.*)$/.match(@doc.namespaces['xmlns'])[1]
    end

    def validate
      version = @expected_version || doc_schema_version
      return ['version not supported'] unless SCHEMA_VERSIONS.include? version

      Nokogiri::XML::Schema(File.open(SCHEMA_FORMAT_PATH % version)).validate @doc
    end
  end
end
