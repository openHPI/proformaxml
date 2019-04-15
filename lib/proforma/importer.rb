# frozen_string_literal: true

require 'nokogiri'

module Proforma
  class Importer
    attr_accessor :doc, :files, :task

    def initialize(xml, files = [])
      self.doc = Nokogiri::XML(File.open(xml), &:noblanks)
      self.files = files
      self.task = Task.new
    end

    def perform
      errors = validate
      puts errors
      raise 'voll nicht valide und so' if errors.any?

      @task_node = doc.xpath('/ns:task', 'ns' => XML_NAMESPACE)

      set_data
      task
    end

    private

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
      task.files = {}
      @task_node.search('files//file').each do |file_node|
        add_file file_node
      end
    end

    def add_file(file_node)
      if /embedded-(bin|txt)-file/.match? file_node.children.first.name
        file = TaskFile.new(
          id: file_node.attributes['id']&.value,
          used_by_grader: file_node.attributes['used-by-grader']&.value,
          visible: file_node.attributes['visible']&.value,
          filename: file_node.children.first.attributes['filename']&.value,
          content: file_node.children.first.text
        )
        task.files[file.id] = file
      end
    end

    def set_external_resources
    end

    def set_model_solutions
    end

    def set_tests
    end

    def set_grading_hints
    end

    def set_meta_data
      task.title = @task_node.at('title').text
      task.description = @task_node.at('description').text
      task.internal_description = @task_node.at('internal-description').text
      task.proglang = @task_node.at('proglang').text
    end

    def validate
      Nokogiri::XML::Schema(File.open(SCHEMA_PATH)).validate doc
    end
  end
end
