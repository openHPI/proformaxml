# frozen_string_literal: true

FactoryBot.define do
  factory :task_file, class: Proforma::TaskFile do
    trait(:populated) do
      sequence(:id) { |n| "file_#{n}" }
      sequence(:binary, &:even?)
      sequence(:content) { |n| [0, 3].include?(n % 4) ? ('test' * 10**5) : 'test' }
      filename { "filename.#{binary ? 'bin' : 'txt'}" }
      used_by_grader { true }
      visible { 'yes' }
      usage_by_lms { 'display' }
      internal_description { 'internal_description' }
      mimetype { 'application/xml' }
    end
    trait(:binary) { binary { true } }
    trait(:text) { binary { false } }
    trait(:small_content) { content { 'test' } }
    trait(:large_content) { content { 'test' * 10**5 } }
  end
end
# attr_accessor :usage_by_lms, :internal_description, :mimetype
