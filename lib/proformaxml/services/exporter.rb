# frozen_string_literal: true

require 'proformaxml/helpers/export_helpers'

module ProformaXML
  class Exporter < ServiceBase
    include ProformaXML::Helpers::ExportHelpers

    def initialize(task:, version: nil)
      super()
      @files = {}
      @task = task
      @version = version || SCHEMA_VERSIONS.first
    end

    def perform
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml_task(xml)
      end
      xmldoc = builder.to_xml
      doc = Nokogiri::XML(xmldoc)
      errors = validate(doc)

      # File.binwrite('../testfile.zip', write_to_zip(xmldoc).string)
      raise PostGenerateValidationError.new(errors) if errors.any?

      write_to_zip(xmldoc)
    end

    private

    def xml_task(xml)
      xml.task(headers) do
        xml.title @task.title
        xml.description @task.description
        add_internal_description_to_xml(xml, @task.internal_description)
        xml.proglang({version: @task.proglang&.dig(:version)}, @task.proglang&.dig(:name))

        add_objects_to_xml(xml)
        add_dachsfisch_node(xml, @task.meta_data, 'meta-data')
      end
    end

    def add_internal_description_to_xml(xml, internal_description)
      xml.send(:'internal-description', internal_description) if internal_description.present?
    end

    def add_objects_to_xml(xml)
      add_dachsfisch_node(xml, @task.submission_restrictions)
      xml.files { files(xml) }
      add_dachsfisch_node(xml, @task.external_resources)
      xml.send(:'model-solutions') { model_solutions(xml) } if @task.model_solutions.any?
      xml.tests { tests(xml) }
      add_dachsfisch_node(xml, @task.grading_hints)
    end

    def files(xml)
      @task.all_files.each do |file|
        xml.file({
          id: file.id, 'used-by-grader' => file.used_by_grader, visible: file.visible,
          'usage-by-lms' => file.usage_by_lms, mimetype: file.mimetype
        }.compact) do
          attach_file(xml, file)
          add_internal_description_to_xml(xml, file.internal_description)
        end
      end
    end

    def model_solutions(xml)
      @task.model_solutions&.each do |model_solution|
        xml.send(:'model-solution', id: model_solution.id) do
          add_filerefs(xml, model_solution)
          add_description_to_xml(xml, model_solution.description)
          add_internal_description_to_xml(xml, model_solution.internal_description)
        end
      end
    end

    def add_filerefs(xml, object)
      return unless object.files.any?

      xml.filerefs do
        object.files.each do |file|
          xml.fileref(refid: file.id) {}
        end
      end
    end

    def tests(xml)
      @task.tests&.each do |test|
        xml.test(id: test.id) do
          xml.title test.title
          add_description_to_xml(xml, test.description)
          add_internal_description_to_xml(xml, test.internal_description)
          xml.send(:'test-type', test.test_type)
          add_test_configuration(xml, test)
        end
      end
    end

    def headers
      {
        'xmlns' => "urn:proforma:v#{@version}",
        'uuid' => @task.uuid,
      }.tap do |header|
        add_parent_uuid_and_lang_to_header(header)
      end
    end

    def validate(doc)
      ProformaXML::Validator.call(doc:, expected_version: @version)
    end

    def write_to_zip(xmldoc)
      Zip::OutputStream.write_buffer do |zio|
        zio.put_next_entry('task.xml')
        zio.write xmldoc
        @task.all_files.each do |file|
          next if file.embed?

          zio.put_next_entry(file.filename)
          zio.write file.content
        end
      end
    end
  end
end
