# frozen_string_literal: true

FactoryBot.define do
  factory :test, class: Proforma::Test do
    files { build_list(:task_file, 1, id: 'test_file_id') }

    trait(:populated) do
      id { 'id' }
      title { 'title' }
      description { 'description' }
      internal_description { 'internal_description' }
      test_type { 'test_type' }
      files { build_list(:task_file, 1, :populated, :small_content, :text) }
      meta_data { {meta: 'data'} }
    end
  end
end
