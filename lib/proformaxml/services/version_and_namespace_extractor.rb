# frozen_string_literal: true

require 'proformaxml/helpers/export_helpers'

module ProformaXML
  class VersionAndNamespaceExtractor < ServiceBase
    def initialize(doc:)
      super()
      @doc = doc
    end

    def perform
      extract_schema_and_version
    end

    private

    def extract_schema_and_version
      namespace_regex = /^urn:proforma:v(\d.*)$/
      potential_namespaces = @doc.namespaces.filter do |_, href|
        href.match? namespace_regex
      end
      return unless potential_namespaces.length == 1

      {
        namespace: potential_namespaces.first[0].gsub('xmlns:', ''),
        version: namespace_regex.match(potential_namespaces.first[1])&.captures&.dig(0),
      }
    end
  end
end
