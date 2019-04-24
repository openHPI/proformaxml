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

    def set_files
      @task.files = {}
      @task_node.search('files//file').each do |file_node|
        add_file file_node
      end
    end

    def add_file(file_node)
      first_child = file_node.children.first
      file = nil
      if /embedded-(bin|txt)-file/.match? first_child.name
        file = TaskFile.new(embedded_file_attributes(file_node.attributes, first_child))
      elsif /attached-(bin|txt)-file/.match? first_child.name
        file = TaskFile.new(attached_file_attributes(file_node.attributes, first_child))
      end
      @task.files[file.id] = file
    end

    def embedded_file_attributes(attributes, file_tag)
      {
        id: attributes['id']&.value,
        used_by_grader: attributes['used-by-grader']&.value,
        visible: attributes['visible']&.value,
        filename: file_tag.attributes['filename']&.value,
        content: file_tag.text
      }
    end

    def attached_file_attributes(attributes, file_tag)
      filename = file_tag.text
      {
        id: attributes['id']&.value,
        used_by_grader: attributes['used-by-grader']&.value,
        visible: attributes['visible']&.value,
        filename: filename,
        content: filestring_from_zip(filename)
      }
    end

    # def set_external_resources; end

    # def set_model_solutions; end

    def set_tests; end

    # def set_grading_hints; end

    def set_meta_data
      @task.title = @task_node.at('title').text
      @task.description = @task_node.at('description').text
      @task.internal_description = @task_node.at('internal-description').text
      @task.proglang = @task_node.at('proglang').text
    end

    def validate
      Nokogiri::XML::Schema(File.open(SCHEMA_PATH)).validate @doc
    end
  end
end
