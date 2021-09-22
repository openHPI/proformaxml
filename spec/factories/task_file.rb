# frozen_string_literal: true

FactoryBot.define do
  factory :task_file, class: 'Proforma::TaskFile' do
    sequence(:id) { |n| "file_#{n}" }
    content { '' }
    used_by_grader { true }
    visible { 'yes' }
    binary { false }

    trait(:populated) do
      sequence(:filename) { |n| "filename_#{n}.#{binary ? 'bin' : 'txt'}" }
      used_by_grader { true }
      visible { 'yes' }
      usage_by_lms { 'display' }
      internal_description { 'internal_description' }
      mimetype { 'application/xml' }
    end
    trait(:binary) { binary { true } }
    trait(:text) { binary { false } }
    trait(:small_content) { content { 'test' } }
    trait(:large_content) { content { 'test' * (10**5) } }
    trait(:invalid) do
      id {}
      content { 'content' }
    end
  end
end
