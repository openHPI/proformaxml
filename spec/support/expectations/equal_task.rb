# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :be_an_equal_task_as do |task2|
  match do |task1|
    equal?(task1, task2)
  end
  failure_message do |actual|
    "#{actual.inspect} is not equal to \n#{task2.inspect}. \nLast checked attribute: #{@last_checked}"
  end

  def equal?(object, other)
    return false unless object.class == other.class
    return proforma_base_equal?(object, other) if object.is_a?(ProformaXML::Base)
    return array_equal?(object, other) if object.is_a?(Array)
    return object.stringify_keys == other.stringify_keys if object.is_a?(Hash)

    object == other
  end

  def proforma_base_equal?(object, other)
    return false unless array_equal?(object.instance_variables, other.instance_variables)

    attributes(object).each do |k, v|
      @last_checked = "#{k}: \n#{v} vs \n#{other.send(k)}"

      return false unless equal?(v, other.send(k))
    end
    true
  end

  def array_equal?(object, other)
    return true if object == other # for []
    return false if object.length != other.length

    object_clone = object.clone
    other_clone = other.clone
    object.each do |element|
      object_index = object_clone.index(element)
      other_index = other_clone.index {|delete_element| equal?(element, delete_element) }
      return false if other_index.nil?

      object_clone.delete_at(object_index)
      other_clone.delete_at(other_index)
    end
    object_clone.empty? && other_clone.empty?
  end

  def attributes(object)
    object.instance_variables.to_h {|e| [e.slice(1, e.length - 1).to_sym, object.instance_variable_get(e)] }
  end
end
