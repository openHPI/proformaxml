# frozen_string_literal: true

module ProformaXML
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
          xml.send :'embedded-bin-file', {filename: file.filename}, Base64.encode64(file.content)
        else
          xml.send :'embedded-txt-file', {filename: file.filename}, file.content
        end
      end

      def add_description_to_xml(xml, description)
        xml.send(:description, description) if description.present?
      end

      def add_test_configuration(xml, test)
        xml.send(:'test-configuration') do
          add_filerefs(xml, test) if test.files
          add_configuration(xml, test.configuration) unless test.configuration.nil?
          if test.meta_data
            xml.send(:'test-meta-data') do
              meta_data(xml, test.meta_data)
            end
          end
        end
      end

      def inner_meta_data(xml, namespace, data)
        data.each do |key, value|
          case value.class.name
            when 'Hash'
              # underscore is used to disambiguate tag names from ruby methods
              xml[namespace].send("#{key}_") do |meta_data_xml|
                inner_meta_data(meta_data_xml, namespace, value)
              end
            else
              xml[namespace].send("#{key}_", value)
          end
        end
      end

      def meta_data(xml, meta_data)
        meta_data.each do |namespace, data|
          inner_meta_data(xml, namespace, data)
        end
      end

      def add_configuration(xml, configuration)
        xml_snippet = Dachsfisch::JSON2XMLConverter.perform(json: configuration.to_json)
        configuration.flat_map {|_, val| val['@xmlns'].to_a }.uniq.each do |namespace|
          xml.doc.root.add_namespace(namespace[0], namespace[1])
        end

        xml << xml_snippet
      end

      def add_namespaces_to_header(header, custom_namespaces)
        custom_namespaces.each do |namespace|
          header["xmlns:#{namespace[:prefix]}"] = namespace[:uri]
        end
      end

      def add_parent_uuid_and_lang_to_header(header)
        header['lang'] = @task.language if @task.language.present?
        header['parent-uuid'] = @task.parent_uuid if @task.parent_uuid.present?
      end
    end
  end
end
