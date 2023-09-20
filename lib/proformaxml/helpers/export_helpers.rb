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
          add_dachsfisch_node(xml, test.configuration)
          add_dachsfisch_node(xml, test.meta_data)
        end
      end

      def add_dachsfisch_node(xml, dachsfisch_node, node_name_fallback = nil)
        if dachsfisch_node.blank?
          xml.send(node_name_fallback, '') if node_name_fallback.present?
          return
        end
        xml_snippet = Dachsfisch::JSON2XMLConverter.perform(json: dachsfisch_node.to_json)
        add_namespaces_for_dachsfisch_node(dachsfisch_node, xml)

        xml << xml_snippet
      end

      def add_parent_uuid_and_lang_to_header(header)
        header['lang'] = @task.language if @task.language.present?
        header['parent-uuid'] = @task.parent_uuid if @task.parent_uuid.present?
      end

      def add_namespaces_for_dachsfisch_node(dachsfisch_node, xml)
        dachsfisch_node.flat_map {|_, val| val['@xmlns'].to_a }.uniq.each do |namespace|
          xml.doc.root.add_namespace(namespace[0], namespace[1]) unless namespace[0] == '$'
        end
      end
    end
  end
end
