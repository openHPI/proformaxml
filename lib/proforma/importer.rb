# frozen_string_literal: true

require 'nokogiri'
require 'zip'

module Proforma
  class Importer
    # attr_accessor :doc, :files, :task

    def initialize(zip)
      @zip = zip
      @files = {}

      xml = filestring_from_zip('example.xml')
      @doc = Nokogiri::XML(xml, &:noblanks)
      @task = Task.new
    end

    def perform
      errors = validate
      puts errors
      raise 'voll nicht valide und so' if errors.any?

      @task_node = @doc.xpath('/ns:task', 'ns' => XML_NAMESPACE)

      set_data
      @task
    end

    private

    def filestring_from_zip(filename)
      Zip::File.open(@zip) do |zip_file|
        return zip_file.glob(filename).first.get_input_stream.read
      end
    end

    def set_data
      set_meta_data
      # set_submission_restrictions
      set_files
      # set_external_resources
      # set_model_solutions
      set_tests
      # set_grading_hints
      # hard_meta_values = %w[submission-restrictions files external-resources model-solutions tests grading-hints]
    end

    # describes restrictions to submissions by student - not used in codeharbor -> skipped
    # def set_submission_restrictions
    # end

    def set_meta_data
      @task.title = @task_node.at('title').text
      @task.description = @task_node.at('description').text
      @task.internal_description = @task_node.at('internal-description').text
      @task.proglang = @task_node.at('proglang').text
    end

    def set_files
      @task.files = {}
      @task_node.search('files//file').each do |file_node|
        add_file file_node
      end
    end

    def set_tests
      @task.tests = []
      @task_node.search('tests//test').each do |test_node|
        add_test test_node
      end
    end

    def add_file(file_node)
      file_tag = file_node.children.first
      file = nil
      if /embedded-(bin|txt)-file/.match? file_tag.name
        file = TaskFile.new(embedded_file_attributes(file_node.attributes, file_tag))
      elsif /attached-(bin|txt)-file/.match? file_tag.name
        file = TaskFile.new(attached_file_attributes(file_node.attributes, file_tag))
      end
      @task.files[file.id] = file
    end

    def embedded_file_attributes(attributes, file_tag)
      shared_file_attributes(attributes).merge(
        filename: file_tag.attributes['filename']&.value,
        content: file_tag.text
      )
    end

    def attached_file_attributes(attributes, file_tag)
      filename = file_tag.text
      shared_file_attributes(attributes).merge(
        filename: filename,
        content: filestring_from_zip(filename)
      )
    end

    def shared_file_attributes(attributes)
      {
        id: attributes['id']&.value,
        used_by_grader: attributes['used-by-grader']&.value,
        usage_by_lms: attributes['usage-by-lms']&.value,
        visible: attributes['visible']&.value
      }
    end

    def add_test(test_node)
      test = Test.new
      test.id = test_node.attributes['id'].value
      test.title = test_node.at('title').text
      test.description = test_node.at('description')&.text
      test.internal_description = test_node.at('internal-description')&.text
      test.test_type = test_node.at('test-type')&.text
      test.files = test_files_from_test_configuration(test_node.at('test-configuration'))
      @task.tests << test
    end

    def test_files_from_test_configuration(test_configuration_node)
      files = []
      test_configuration_node.search('filerefs//fileref').each do |fileref_node|
        fileref = fileref_node.attributes['refid'].value
        files << @task.files[fileref]
      end
      files
    end

    # def set_external_resources; end
    # def set_model_solutions; end
    # def set_grading_hints; end

    def validate
      Nokogiri::XML::Schema(File.open(SCHEMA_PATH)).validate @doc
    end
  end
end
