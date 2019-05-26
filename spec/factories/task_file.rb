# frozen_string_literal: true

FactoryBot.define do
  factory :task_file, class: Proforma::TaskFile do
    sequence(:id) { |n| "file_#{n}" }
    content { '' }
    used_by_grader { true }
    visible { 'yes' }
    binary { false }

    trait(:populated) do
      # 1st: test, 2nd binary, ... not used rn
      # sequence(:binary, &:even?)
      # 1st & 2nd: small, 3rd & 4th large, ... not used rn
      # sequence(:content) { |n| [0, 3].include?(n % 4) ? ('test' * 10**5) : 'test' }
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
    trait(:large_content) { content { 'test' * 10**5 } }
    trait(:invalid) do
      id {}
      content { 'content' }
    end
  end
end
