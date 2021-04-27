# frozen_string_literal: true

require 'rspec/expectations'

RSpec::Matchers.define :be_an_equal_task_as do |other|
  match do |task|
    equal?(task, other)
  end
  failure_message do |actual|
    # :nocov:
    "#{actual.inspect} is not equal to \n#{other.inspect}. \nLast checked attribute: #{@last_checked}"
    # :nocov:
  end

  def equal?(object, other)
    return false unless object.class == other.class
    return proforma_base_equal?(object, other) if object.is_a?(Proforma::Base)
    return array_equal?(object, other) if object.is_a?(Array)
    return object.stringify_keys == other.stringify_keys if object.is_a?(Hash)

    object == other
  end

  def proforma_base_equal?(object, other)
    return false unless object.instance_variables == other.instance_variables

    attributes(object).each do |k, v|
      @last_checked = "#{k}: \n#{v} vs \n#{other.send(k)}"

      return false unless equal?(v, other.send(k))
    end
    true
  end

  def array_equal?(object, other)
    return true if object == other # for []

    object.map do |element|
      other.map do |other_element|
        equal?(element, other_element)
      end.any?
    end.all?
  end

  def attributes(object)
    object.instance_variables.map { |e| [e.slice(1, e.length - 1).to_sym, object.instance_variable_get(e)] }.to_h
  end
end
