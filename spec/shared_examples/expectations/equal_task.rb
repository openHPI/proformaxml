# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :be_an_equal_task_as do |other|
  match do |task|
    unless equal_task_meta_data?(task, other) &&
           equal_model_solutions?(task.model_solutions, other.model_solutions) &&
           equal_tests?(task.tests, other.tests) &&
           equal_files?(task.files, other.files)
      return false
    end

    true
  end

  def equal_task_meta_data?(task1, task2)
    return false unless task_attributes(task1) == task_attributes(task2)

    true
  end

  def equal_model_solutions?(model_solutions1, model_solutions2)
    return false unless model_solutions1&.length == model_solutions2&.length
    return true if model_solutions1.nil?

    model_solutions1.zip(model_solutions2).map { |ms1, ms2| equal_model_solution?(ms1, ms2) }.all?
    true
  end

  def equal_tests?(tests1, tests2)
    return false unless tests1&.length == tests2&.length
    return true if tests1.nil?

    tests1.zip(tests2).map { |t1, t2| equal_test?(t1, t2) }.all?
    true
  end

  def equal_files?(files1, files2)
    return false unless files1&.length == files2&.length
    return true if files1.nil?

    files1.zip(files2).map { |f1, f2| equal_file?(f1, f2) }.all?
    true
  end

  def equal_model_solution?(model_solution1, model_solution2)
    return false unless model_solution_attributes(model_solution1) == model_solution_attributes(model_solution2)

    equal_files?(model_solution1.files, model_solution2.files)
  end

  def equal_test?(test1, test2)
    return false unless test_attributes(test1) == test_attributes(test2)

    equal_files?(test1.files, test2.files)
  end

  def equal_file?(file1, file2)
    return false unless task_file_attributes(file1) == task_file_attributes(file2)

    true
  end

  def task_file_attributes(file)
    {id: file.id,
     content: file.content,
     filename: file.filename,
     used_by_grader: file.used_by_grader,
     visible: file.visible,
     usage_by_lms: file.usage_by_lms,
     binary: file.binary,
     internal_description: file.internal_description,
     mimetype: file.mimetype}
  end

  def test_attributes(test)
    {
      id: test.id,
      title: test.title,
      description: test.description,
      internal_description: test.internal_description,
      test_type: test.test_type,
      meta_data: test.meta_data
    }
  end

  def model_solution_attributes(model_solution)
    {
      id: model_solution.id,
      description: model_solution.description,
      internal_description: model_solution.internal_description
    }
  end

  def task_attributes(task)
    {
      title: task.title,
      description: task.description,
      internal_description: task.internal_description,
      proglang: task.proglang,
      uuid: task.uuid,
      parent_uuid: task.parent_uuid,
      language: task.language
    }
  end
end
