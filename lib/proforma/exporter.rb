# frozen_string_literal: true

module Proforma
  class Exporter
    def initialize(task, version = nil)
      @files = {}
      @task = task
      @version = version || SCHEMA_VERSIONS.first
      add_placeholders
    end

    def perform
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml_task(xml)
      end
      xmldoc = builder.to_xml
      doc = Nokogiri::XML(xmldoc)
      errors = validate(doc)

      raise PostGenerateValidationError, errors if errors.any?

      # File.open('../testfile.zip', 'wb') { |file| file.write(write_to_zip(xmldoc).string) }
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
        add_meta_data(xml)
      end
    end

    def add_internal_description_to_xml(xml, internal_description)
      xml.send('internal-description', internal_description) unless internal_description.blank?
    end

    def add_meta_data(xml)
      xml.send('meta-data') {}
    end

    def add_objects_to_xml(xml)
      xml.files { files(xml) }
      xml.send('model-solutions') { model_solutions(xml) }
      xml.tests { tests(xml) }
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

    def attach_file(xml, file)
      if file.embed?
        if file.binary
          xml.send 'embedded-bin-file', {filename: file.filename}, Base64.encode64(file.content)
        else
          xml.send 'embedded-txt-file', {filename: file.filename}, file.content
        end
      else
        xml.send "attached-#{file.binary ? 'bin' : 'txt'}-file", file.filename
      end
    end

    def model_solutions(xml)
      @task.model_solutions&.each do |model_solution|
        xml.send('model-solution', id: model_solution.id) do
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
          xml.send('test-type', test.test_type)
          add_test_configuration(xml, test)
        end
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
            test.meta_data.each { |key, value| xml['c'].send(key.to_s + '_', value) }
          end
        end
      end
    end

    def add_unittest_configuration(xml, test)
      return unless test.test_type == 'unittest' && !test.configuration.nil?

      xml['unit'].unittest(framework: test.configuration['framework'], version: test.configuration['version']) do |unit|
        unit['unit'].send('entry-point', test.configuration['entry-point'])
      end
    end

    # ms-placeholder should be able to go as soon as profoma 2.1 is released https://github.com/ProFormA/proformaxml/issues/5
    def add_placeholders
      return if @task.model_solutions&.any?

      file = TaskFile.new(content: '', id: 'ms-placeholder-file', used_by_grader: false, visible: 'no', binary: false)
      model_solution = ModelSolution.new(id: 'ms-placeholder', files: [file])
      @task.model_solutions = [model_solution]
    end

    def headers
      {
        'xmlns' => "urn:proforma:v#{@version}",
        'uuid' => @task.uuid
      }.tap do |header|
        add_codeharbor_namespace_to_header(header)
        add_unittest_namespace_to_header(header)
        header['lang'] = @task.language unless @task.language.blank?
        header['parent-uuid'] = @task.parent_uuid unless @task.parent_uuid.blank?
      end
    end

    def add_codeharbor_namespace_to_header(header)
      header['xmlns:c'] = 'codeharbor' if @task.tests.filter { |t| t.meta_data&.any? }.any?
    end

    def add_unittest_namespace_to_header(header)
      header['xmlns:unit'] = 'urn:proforma:tests:unittest:v1.1' if @task.tests.filter { |t| t.test_type == 'unittest' }.any?
    end

    def validate(doc)
      validator = Proforma::Validator.new doc, @version
      validator.perform
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
