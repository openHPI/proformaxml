# frozen_string_literal: true

require 'nokogiri'
require 'securerandom'
require 'zip'

module Proforma
  class Exporter
    attr_accessor :doc, :files, :task

    def initialize(task)
      # @zip = zip
      @files = {}
      @task = task


      # xml = filestring_from_zip('example.xml')
      # @doc = Nokogiri::XML(xml, &:noblanks)
      # self.doc = @doc
    end

    def perform
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.task(headers) do
          xml.title 'title'
          xml.description 'Description'
          xml.send('internal-description', 'InternalDescription')
          xml.proglang({version: '2.6'}, 'Ruby')
          xml.files do
            xml.file(id: 'file1', 'used-by-grader' => '1', visible: 'no') do
              xml.send 'embedded-bin-file', {filename: 'bin/Filename'}, 'MTAxMDAxMTAxMCBmaWxlYmluY29uZW50'
            end
            xml.file(id: 'file2', 'used-by-grader' => '1','mimetype' => 'dunno', visible: 'yes') do
              xml.send 'embedded-bin-file', {filename: 'bin/Filename2'}, 'ZmlsZWJvbmNvbmVudCAxMDEwMDExMDEw'
            end
            xml.file(id: 'file3', 'used-by-grader' => '1', visible: 'delayed') do
              xml.send 'embedded-txt-file', {filename: 'txt/Filename'}, 'textiger text'
            end
            xml.file(id: 'file4', 'used-by-grader' => '1','usage-by-lms' => 'edit', visible: 'no') do
              xml.send 'embedded-txt-file', {filename: 'Filename'}, 'TEXT'
            end
          end
          xml.send('model-solutions') do
            xml.send('model-solution', id: 'msid1') do
              xml.filerefs do
                xml.fileref(refid: 'file2')
              end
            end
            xml.send('model-solution', id: 'msid2') do
              xml.filerefs do
                xml.fileref(refid: 'file4')
              end
            end
          end
          xml.tests do
            xml.test(id: 'test1') do
              xml.title 'Testtestfile'
              xml.description 'TestDescription'
              xml.send('test-type', 'TestYpe')
              xml.send('test-configuration') do
                xml.filerefs do
                  xml.fileref refid: 'file1'
                end
                xml.send('test-meta-data') do
                  xml.send('c:feedback-message', 'Feedbackmessage')
                  xml.send('c:testing-framework', 'Rspec')
                  xml.send('c:testing-framework-version', '1')
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
        # exercise.exercise_files.each do |file|
        #   if file.attachment.original_filename
        #     zio.put_next_entry(file.attachment.original_filename)
        #     zio.write Paperclip.io_adapters.for(file.attachment).read
        #   end
        # end
      end
      File.open('tesfile.zip', 'wb') { |file| file.write(stringio.string) }
      stringio
    end

    def headers
      {
        'xmlns' => 'urn:proforma:v2.0.1',
        'xmlns:c' => 'codeharbor',
        'xsi:schemaLocation' => 'urn:proforma:v2.0.1 schema.xsd',
        'uuid' => SecureRandom.uuid,
        # 'parent-uuid' => 'string',
        # 'lang' => @task.language,
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
      }
    end

    def validate(doc)
      xsd = Nokogiri::XML::Schema(File.open(SCHEMA_PATH))
      xsd.validate(doc)
    end
  end
end
