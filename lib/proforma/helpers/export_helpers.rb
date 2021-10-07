# frozen_string_literal: true

module Proforma
  module Helpers
    module ExportHelpers
      def attach_file(xml, file)
        if file.embed?
          embed_file(file, xml)
        else
          xml.send "attached-#{file.binary ? 'bin' : 'txt'}-file", file.filename
        end
      end

      def embed_file(file, xml)
        if file.binary
          xml.send 'embedded-bin-file', {filename: file.filename}, Base64.encode64(file.content)
        else
          xml.send 'embedded-txt-file', {filename: file.filename}, file.content
        end
      end

      def add_description_to_xml(xml, description)
        xml.send('description', description) unless description.blank?
      end

      def add_test_configuration(xml, test)
        xml.send('test-configuration') do
          add_filerefs(xml, test) if test.files
          add_unittest_configuration(xml, test)
          if test.meta_data
            xml.send('test-meta-data') do
              meta_data(xml, test.meta_data)
            end
          end
        end
      end

      def inner_meta_data(xml, namespace, _key, data)
        data.each do |key, value|
          xml[namespace].send("#{key}_", data[key]) if value.is_a? String

          next unless value.is_a? Hash

          xml[namespace].send("#{key}_") do |xml|
            inner_meta_data(xml, namespace, key, value)
          end
        end
      end

      def meta_data(xml, meta_data)
        # underscore is used to disambiguate tag names from ruby methods
        meta_data.each do |namespace, data|
          # if data.is_a? String
          #   data
          # end
          data.each do |key, value|
            xml[namespace].send("#{key}_", data[key]) if value.is_a? String
            inner_meta_data(xml, namespace, key, value) if value.is_a? Hash
          end
        end
      end

      def add_unittest_configuration(xml, test)
        return unless test.test_type == 'unittest' && !test.configuration.nil?

        xml['unit'].unittest(framework: test.configuration['framework'], version: test.configuration['version']) do |unit|
          unit['unit'].send('entry-point', test.configuration['entry-point'])
        end
      end

      def add_namespaces_to_header(header, custom_namespaces)
        custom_namespaces.each do |namespace|
          header["xmlns:#{namespace[:prefix]}"] = namespace[:uri]
        end
        header['xmlns:unit'] = 'urn:proforma:tests:unittest:v1.1' if @task.tests.filter { |t| t.test_type == 'unittest' }.any?
      end

      def add_parent_uuid_and_lang_to_header(header)
        header['lang'] = @task.language unless @task.language.blank?
        header['parent-uuid'] = @task.parent_uuid unless @task.parent_uuid.blank?
      end
    end
  end
end
