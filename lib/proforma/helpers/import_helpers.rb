# frozen_string_literal: true

module Proforma
  module Helpers
    module ImportHelpers
      def set_hash_value_if_present(hash:, name:, attributes: nil, value_overwrite: nil)
        raise unless attributes || value_overwrite

        value = value_overwrite || attributes[name.to_s]&.value
        hash[name.underscore.to_sym] = value if value.present?
      end

      def set_value_from_xml(object:, node:, name:, attribute: false, check_presence: true)
        value = value_from_node(name, node, attribute)
        return if check_presence && !value.present?

        set_value(object: object, name: (name.is_a?(Array) ? name[1] : name).underscore, value: value)
      end

      def set_value(object:, name:, value:)
        if object.is_a? Hash
          object[name] = value
        else
          object.send("#{name}=", value)
        end
      end

      def embedded_file_attributes(attributes, file_tag)
        shared = shared_file_attributes(attributes, file_tag)
        shared.merge(
          content: content_from_file_tag(file_tag, shared[:binary])
        ).tap do |hash|
          hash[:filename] = file_tag.attributes['filename']&.value unless file_tag.attributes['filename']&.value.blank?
        end
      end

      def attached_file_attributes(attributes, file_tag)
        filename = file_tag.text
        shared_file_attributes(attributes, file_tag).merge(filename: filename,
                                                           content: filestring_from_zip(filename))
      end

      def shared_file_attributes(attributes, file_tag)
        {
          id: attributes['id']&.value,
          used_by_grader: attributes['used-by-grader']&.value == 'true',
          visible: attributes['visible']&.value,
          binary: /-bin-file/.match?(file_tag.name)
        }.tap do |hash|
          set_hash_value_if_present(hash: hash, name: 'usage-by-lms', attributes: attributes)
          set_value_from_xml(object: hash, node: file_tag.parent, name: 'internal-description')
          set_hash_value_if_present(hash: hash, name: 'mimetype', attributes: attributes)
        end
      end

      def add_test_configuration(test, test_node)
        test_configuration_node = test_node.xpath('xmlns:test-configuration')
        test.files = test_files_from_test_configuration(test_configuration_node)
        test.configuration = extra_configuration_from_test_configuration(test_configuration_node)
        meta_data_node = test_node.xpath('xmlns:test-configuration').xpath('xmlns:test-meta-data')
        test.meta_data = meta_data(meta_data_node) unless meta_data_node.blank?
      end

      def extra_configuration_from_test_configuration(test_configuration_node)
        configuration_any_node = test_configuration_node.children.reject do |c|
          %w[filerefs timeout externalresourcerefs test-meta-data].include? c.name
        end.first
        nil if configuration_any_node.nil?

        # any_data_tag(configuration_any_node)
      end

      def test_files_from_test_configuration(test_configuration_node)
        files_from_filerefs(test_configuration_node.search('filerefs'))
      end

      def meta_data(meta_data_node)
        {}.tap do |any_data|
          return any_data if meta_data_node.nil?

          meta_data_node.children.each do |any_data_tag|
            inner_hash = set_any_meta_data(any_data_tag.name, any_data_tag)
            namespace_hash = any_data[any_data_tag.namespace.prefix.to_sym] || {}
            namespace_hash.merge! inner_hash
            any_data[any_data_tag.namespace.prefix.to_sym] = namespace_hash
          end
        end
      end

      def set_any_meta_data(key, any_data_node)
        {}.tap do |any_data|
          any_data_node.children.each do |node|
            any_data[key.to_sym] = node.node_type == Nokogiri::XML::Node::TEXT_NODE ? node.text : any_data[key.to_sym] || {}
            any_data[key.to_sym].merge! set_any_meta_data(node.name, node) if node.node_type == Nokogiri::XML::Node::ELEMENT_NODE
          end
        end
      end

      private

      def value_from_node(name, node, attribute)
        xml_name = name.is_a?(Array) ? name[0] : name
        attribute ? node.attribute(xml_name)&.value : node.xpath("xmlns:#{xml_name}").text
      end

      def content_from_file_tag(file_tag, binary)
        binary ? Base64.decode64(file_tag.text) : file_tag.text
      end
    end
  end
end
