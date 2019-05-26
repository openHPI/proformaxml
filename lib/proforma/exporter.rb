# frozen_string_literal: true

module Proforma
  class Exporter
    def initialize(task)
      @files = {}
      @task = task

      add_placeholders
    end

    def perform
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.task(headers) do
          xml.title @task.title
          xml.description @task.description
          xml.send('internal-description', @task.internal_description) unless @task.internal_description.blank?
          xml.proglang({version: @task.proglang&.dig(:version)}, @task.proglang&.dig(:name))
          xml.files do
            @task.all_files.each do |file|
              xml.file({
                id: file.id,
                'used-by-grader' => file.used_by_grader,
                visible: file.visible,
                'usage-by-lms' => file.usage_by_lms,
                mimetype: file.mimetype
              }.compact) do
                if file.embed?
                  if file.binary
                    xml.send 'embedded-bin-file', {filename: file.filename}, Base64.encode64(file.content)
                  else
                    xml.send 'embedded-txt-file', {filename: file.filename}, file.content
                  end
                else
                  xml.send "attached-#{file.binary ? 'bin' : 'txt'}-file", file.filename
                end
                xml.send 'internal-description', file.internal_description unless file.internal_description.blank?
              end
            end
          end
          xml.send('model-solutions') do
            @task.model_solutions&.each do |model_solution|
              xml.send('model-solution', id: model_solution.id) do
                xml.filerefs do
                  model_solution.files.each do |file|
                    xml.fileref(refid: file.id) {}
                  end
                end
                xml.description model_solution.description unless model_solution.description.blank?
                xml.send('internal-description', model_solution.internal_description) unless model_solution.internal_description.blank?
              end
            end
          end
          xml.tests do
            @task.tests&.each do |test|
              xml.test(id: test.id) do
                xml.title test.title
                xml.description test.description unless test.description.blank?
                xml.send('internal-description', test.internal_description) unless test.internal_description.blank?
                xml.send('test-type', test.test_type)
                xml.send('test-configuration') do
                  if test.files
                    xml.filerefs do
                      test.files.each do |file|
                        xml.fileref refid: file.id
                      end
                    end
                  end
                  if test.meta_data
                    xml.send('test-meta-data') do
                      test.meta_data&.each do |key, value|
                        xml['c'].send(key, value)
                      end
                    end
                  end
                end
              end
            end
          end
          xml.send('meta-data')
        end
      end
      xmldoc = builder.to_xml
      doc = Nokogiri::XML(xmldoc)
      errors = validate(doc)

      raise PostGenerateValidationError, errors if errors.any?

      stringio = Zip::OutputStream.write_buffer do |zio|
        zio.put_next_entry('task.xml')
        zio.write xmldoc
        @task.all_files.each do |file|
          next if file.embed?

          zio.put_next_entry(file.filename)
          zio.write file.content
        end
      end
      File.open('../testfile.zip', 'wb') { |file| file.write(stringio.string) }
      stringio
    end

    private

    # ms-placeholder should be able to go as soon as profoma 2.1 is released https://github.com/ProFormA/proformaxml/issues/5
    def add_placeholders
      return if @task.model_solutions&.any?

      file = TaskFile.new(content: '', id: 'ms-placeholder-file', used_by_grader: false, visible: 'no', binary: false)
      model_solution = ModelSolution.new(id: 'ms-placeholder', files: [file])
      @task.model_solutions = [model_solution]
    end

    def headers
      {
        'xmlns' => 'urn:proforma:v2.0.1',
        'uuid' => @task.uuid
      }.tap do |h|
        h['xmlns:c'] = 'codeharbor' if @task.tests&.any?
        h['lang'] = @task.language unless @task.language.blank?
        h['parent-uuid'] = @task.parent_uuid unless @task.parent_uuid.blank?
      end
    end

    def validate(doc)
      xsd = Nokogiri::XML::Schema(File.open(SCHEMA_PATH))
      xsd.validate(doc)
    end
  end
end
