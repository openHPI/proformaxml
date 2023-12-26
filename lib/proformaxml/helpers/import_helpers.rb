# frozen_string_literal: true

module ProformaXML
  module Helpers
    module ImportHelpers
      CONFIGURATION_NODES = %w[filerefs timeout externalresourcerefs test-meta-data].freeze

      def set_hash_value_if_present(hash:, name:, attributes: nil, value_overwrite: nil)
        raise unless attributes || value_overwrite

        value = value_overwrite || attributes[name.to_s]&.value
        hash[name.underscore.to_sym] = value if value.present?
      end

      def set_value_from_xml(object:, node:, name:, attribute: false, check_presence: true)
        value = value_from_node(name, node, attribute)
        return if check_presence && value.blank?

        set_value(object:, name: (name.is_a?(Array) ? name[1] : name).underscore, value:)
      end

      def set_value(object:, name:, value:)
        if object.is_a? Hash
          object[name] = value
        else
          object.send(:"#{name}=", value)
        end
      end

      def embedded_file_attributes(attributes, file_tag)
        shared = shared_file_attributes(attributes, file_tag)
        shared.merge(
          content: content_from_file_tag(file_tag, shared[:binary])
        ).tap do |hash|
          hash[:filename] = file_tag.attributes['filename']&.value if file_tag.attributes['filename']&.value.present?
        end
      end

      def attached_file_attributes(attributes, file_tag)
        filename = file_tag.text
        shared_file_attributes(attributes, file_tag).merge(filename:,
          content: filestring_from_zip(filename))
      end

      def shared_file_attributes(attributes, file_tag)
        {
          id: attributes['id']&.value,
          used_by_grader: attributes['used-by-grader']&.value == 'true',
          visible: attributes['visible']&.value,
          binary: file_tag.name.include?('-bin-file'),
        }.tap do |hash|
          set_hash_value_if_present(hash:, name: 'usage-by-lms', attributes:)
          set_value_from_xml(object: hash, node: file_tag.parent, name: 'internal-description')
          set_hash_value_if_present(hash:, name: 'mimetype', attributes:)
        end
      end

      def add_test_configuration(test, test_node)
        test_configuration_node = test_node.xpath("#{@pro_ns}:test-configuration")
        test.files = test_files_from_test_configuration(test_configuration_node)
        test.configuration = extra_configuration_from_test_configuration(test_configuration_node)
        meta_data_node = test_node.xpath("#{@pro_ns}:test-configuration").xpath("#{@pro_ns}:test-meta-data")
        test.meta_data = convert_xml_node_to_json(meta_data_node) if meta_data_node.present?
      end

      def extra_configuration_from_test_configuration(test_configuration_node)
        configuration_any_nodes = test_configuration_node.children.reject {|c| CONFIGURATION_NODES.include? c.name }
        return nil if configuration_any_nodes.empty?

        {}.tap do |config_hash|
          configuration_any_nodes.each do |config_node|
            config_hash.merge!(convert_xml_node_to_json(config_node)) {|key, oldval, newval| key == '@@order' ? oldval + newval : newval }
          end
        end
      end

      def test_files_from_test_configuration(test_configuration_node)
        files_from_filerefs(test_configuration_node.xpath("#{@pro_ns}:filerefs"))
      end

      private

      def convert_xml_node_to_json(any_node)
        xml_snippet = Nokogiri::XML::DocumentFragment.new(Nokogiri::XML::Document.new, any_node)
        all_namespaces_without_default(any_node).each do |namespace|
          xml_snippet.children.first.add_namespace_definition(namespace[:prefix], namespace[:href])
        end
        xml_without_custom_default_ns = xml_snippet.to_xml.gsub(%r{(</?)#{custom_default_namespace_prefix(any_node)}:}, '\1')
        JSON.parse(Dachsfisch::XML2JSONConverter.perform(xml: xml_without_custom_default_ns))
      end

      def all_namespaces_without_default(node)
        node.xpath('.|.//*').map(&:namespace).reject do |ns|
          ns.prefix.nil? || ns.href.match?(/^urn:proforma:v\d.*$/)
        end.map {|ns| {prefix: ns.prefix, href: ns.href} }.uniq
      end

      def custom_default_namespace_prefix(node)
        node.xpath('.|.//*').map(&:namespace).filter do |ns|
          ns.href.match?(/^urn:proforma:v\d.*$/)
        end.map(&:prefix).first
      end

      def value_from_node(name, node, attribute)
        xml_name = name.is_a?(Array) ? name[0] : name
        attribute ? node.attribute(xml_name)&.value : node.xpath("#{@pro_ns}:#{xml_name}").text
      end

      def content_from_file_tag(file_tag, binary)
        binary ? Base64.decode64(file_tag.text) : file_tag.text
      end
    end
  end
end
