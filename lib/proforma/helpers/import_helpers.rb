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
        xml_name = name.is_a?(Array) ? name[0] : name

        value = attribute ? node.attribute(xml_name)&.value : node.xpath("xmlns:#{xml_name}").text
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
          content: shared[:binary] ? Base64.decode64(file_tag.text) : file_tag.text
        ).tap { |hash| hash[:filename] = file_tag.attributes['filename']&.value unless file_tag.attributes['filename']&.value.blank? }
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
        test.meta_data = any_data_tag(meta_data_node.first) unless meta_data_node.blank?
      end

      def extra_configuration_from_test_configuration(test_configuration_node)
        configuration_any_node = test_configuration_node.children.reject do |c|
          %w[filerefs timeout externalresourcerefs test-meta-data].include? c.name
        end.first
        return if configuration_any_node.nil?

        any_data_tag(configuration_any_node).tap { |hash| hash['type'] = configuration_any_node.name }
      end

      def test_files_from_test_configuration(test_configuration_node)
        files_from_filerefs(test_configuration_node.search('filerefs'))
      end

      def any_data_tag(any_data_node)
        {}.tap do |any_data|
          return any_data if any_data_node.nil?

          any_data_node.attributes.values.each { |attribute| any_data[attribute.name] = attribute.value }
          any_data_node.children.each { |any_data_tag| any_data[any_data_tag.name] = any_data_tag.children.first.text }
        end
      end
    end
  end
end
