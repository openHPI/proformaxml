# frozen_string_literal: true

FactoryBot.define do
  factory :test, class: 'Proforma::Test' do
    sequence(:files) { |n| build_list(:task_file, 1, id: "test_file_#{n}") }
    sequence(:id) { |n| "test_#{n}" }
    title { 'title' }
    test_type { 'test_type' }
    configuration { nil }

    trait(:no_file) do
      files {}
    end

    trait(:populated) do
      title { 'title' }
      description { 'description' }
      internal_description { 'internal_description' }
      files { build_list(:task_file, 1, :populated, :small_content, :text) }
    end

    trait(:with_meta_data) do
      meta_data { {namespace: {test_meta: 'data', test: 'test_data'}} }
    end

    trait(:with_multiple_files) do
      files { build_list(:task_file, 2, :populated, :small_content, :text) }
    end
  end
end
