# frozen_string_literal: true

FactoryBot.define do
  factory :task_file, class: Proforma::TaskFile do
    trait(:small_content) { content { 'test' } }
    trait(:large_content) { content { 'test' * 10**5 } }
  end
end
