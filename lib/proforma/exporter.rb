# frozen_string_literal: true

module Proforma
  class Exporter
    attr_accessor :doc, :files, :task

    def initialize(task)
      # @zip = zip
      @files = {}
      @task = task

      add_placeholders

      # xml = filestring_from_zip('example.xml')
      # @doc = Nokogiri::XML(xml, &:noblanks)
      # self.doc = @doc
    end

    def add_placeholders
      return if @task.model_solutions&.any?

      file = TaskFile.new(content: '', id: 'ms-placeholder-file', used_by_grader: false, visible: 'no')
      model_solution = ModelSolution.new(id: 'ms-placeholder', files: [file])
      @task.model_solutions = [model_solution]
    end

    def perform
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.task(headers) do
          xml.title @task.title
          xml.description @task.description
          xml.send('internal-description', @task.internal_description)
          xml.proglang({version: @task.proglang[:version]}, @task.proglang[:name])
          xml.files do
            @task.all_files.each do |file|
              xml.file(id: file.id, 'used-by-grader' => file.used_by_grader, visible: file.visible) do
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
                xml.description model_solution.description if model_solution.description
                xml.send('internal-description', model_solution.internal_description) if model_solution.internal_description
              end
            end
          end
          xml.tests do
            @task.tests&.each do |test|
              xml.test(id: test.id) do
                xml.title test.title
                xml.description test.description
                xml.send('internal-description', test.internal_description)
                xml.send('test-type', test.test_type)
                xml.send('test-configuration') do
                  xml.filerefs do
                    test.files.each do |file|
                      xml.fileref refid: file.id
                    end
                  end
                  xml.send('test-meta-data') do
                    test.meta_data.each do |key, value|
                      xml['c'].send(key, value)
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
      if errors.any?
        puts 'errors: '
        puts errors
        raise 'voll nicht valide und so'
      end
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

    def headers
      {
        'xmlns' => 'urn:proforma:v2.0.1',
        'xmlns:c' => 'codeharbor',
        'xsi:schemaLocation' => 'urn:proforma:v2.0.1 schema.xsd',
        'uuid' => @task.uuid,
        'parent-uuid' => @task.parent_uuid,
        'lang' => @task.language,
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
      }
    end

    def validate(doc)
      xsd = Nokogiri::XML::Schema(File.open(SCHEMA_PATH))
      xsd.validate(doc)
    end
  end
end
