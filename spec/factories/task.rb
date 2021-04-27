# frozen_string_literal: true

FactoryBot.define do
  factory :task, class: 'Proforma::Task' do
    trait(:populated) do
      title { 'title' }
      description { 'description' }
      internal_description { 'internal_description' }
      proglang { {name: 'Ruby', version: '1'} }
      uuid { 'uuid' }
      parent_uuid { 'parent_uuid' }
      language { 'language' }
    end

    trait(:with_embedded_txt_file) { files { build_list(:task_file, 1, :populated, :small_content, :text) } }
    trait(:with_multiple_embedded_txt_files) { files { build_list(:task_file, 5, :populated, :small_content, :text) } }
    trait(:with_embedded_bin_file) { files { build_list(:task_file, 1, :populated, :small_content, :binary) } }
    trait(:with_attached_txt_file) { files { build_list(:task_file, 1, :populated, :large_content, :text) } }
    trait(:with_attached_bin_file) { files { build_list(:task_file, 1, :populated, :large_content, :binary) } }

    trait(:with_model_solution) { model_solutions { build_list(:model_solution, 1, :populated) } }
    trait(:with_test) { tests { build_list(:test, 1, :populated) } }
    trait(:with_test_with_meta_data) { tests { build_list(:test, 1, :populated, :with_meta_data) } }

    trait(:with_everything) do
      with_multiple_embedded_txt_files
      with_model_solution
      with_test_with_meta_data
    end

    trait(:invalid) { files { build_list(:task_file, 1, :invalid) } }
  end
end
