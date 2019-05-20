# frozen_string_literal: true

FactoryBot.define do
  factory :task, class: Proforma::Task do
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
    trait(:with_embedded_bin_file) { files { build_list(:task_file, 1, :populated, :small_content, :binary) } }
    trait(:with_attached_txt_file) { files { build_list(:task_file, 1, :populated, :large_content, :text) } }
    trait(:with_attached_bin_file) { files { build_list(:task_file, 1, :populated, :large_content, :binary) } }
    # trait(:with_files) { files { build_list(:task_file, 4, :populated) } }
    trait(:with_model_solution) { model_solutions { build_list(:model_solution, 1, :populated) } }
    trait(:with_test) { tests { build_list(:test, 1, :populated) } }

    trait(:invalid) { files { build_list(:task_file, 1, :invalid) } }
  end
end
