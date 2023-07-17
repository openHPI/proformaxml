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

    def custom_test_config_validation
      return [] if @doc.namespaces.values.none? {|ns| ns.start_with?('urn:proforma:tests:') }

      validate_proforma_test_configuration
    end

    def validate_proforma_test_configuration
      @doc.xpath('/xmlns:task/xmlns:tests/xmlns:test/xmlns:test-configuration').map do |test_config|
        test_config.children.select do |c|
          c.namespace&.href&.start_with?('urn:proforma:tests:')
        end.map {|config| validate_proforma_config_node config }
      end.flatten
    end

    def validate_proforma_config_node(config_node)
      tmp_doc = node_as_doc_with_namespace(config_node)

      return unless TEST_TYPE_SCHEMA_NAMES.include? config_node.name

      schema = Nokogiri::XML::Schema(File.read(Proforma::SCHEMA_FORMAT_PATH % config_node.name))
      schema.validate(Nokogiri::XML(tmp_doc.to_xml))
    end

    def node_as_doc_with_namespace(config_node)
      Nokogiri::XML(config_node.to_xml).tap do |doc|
        doc.children.first.add_namespace_definition(config_node.namespace.prefix, config_node.namespace.href)
      end
    end

    def validate
      return ['no proforma version found'] if doc_schema_version.nil?

      version = @expected_version || doc_schema_version
      return ['version not supported'] unless SCHEMA_VERSIONS.include? version

      Nokogiri::XML::Schema(File.open(SCHEMA_FORMAT_PATH % version)).validate(@doc) + custom_test_config_validation
    end
  end
end
