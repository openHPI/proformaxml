# frozen_string_literal: true

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
      @doc_schema_version ||= /^urn:proforma:v(.*)$/.match(@doc.namespaces['xmlns'])&.captures&.dig(0)
    end

    def node_as_doc_with_namespace(config_node)
      doc = Nokogiri::XML::Document.new
      doc.add_child(config_node.dup)
      doc
    end

    def validate
      return ['no proforma version found'] if doc_schema_version.nil?

      version = @expected_version || doc_schema_version
      return ['version not supported'] unless SCHEMA_VERSIONS.include? version

      # Both validations return an array of errors, which are empty if the validation was successful.
      validate_task(version) + validate_test_configuration
    end

    def validate_task(version)
      Nokogiri::XML::Schema(File.open(SCHEMA_FORMAT_PATH % version)).validate(@doc)
    end

    def validate_test_configuration
      @doc.xpath('/xmlns:task/xmlns:tests/xmlns:test/xmlns:test-configuration').flat_map do |test_config|
        test_config.children.flat_map do |config_node|
          next [] unless config_node.namespace&.href&.start_with?('urn:proforma:tests:')
          next [] unless TEST_TYPE_SCHEMA_NAMES.include? config_node.name

          schema = Nokogiri::XML::Schema(File.read(SCHEMA_FORMAT_PATH % config_node.name))
          schema.validate(node_as_doc_with_namespace(config_node))
        end
      end
    end
  end
end
