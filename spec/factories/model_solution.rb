# frozen_string_literal: true

FactoryBot.define do
  factory :model_solution, class: 'Proforma::ModelSolution' do
    sequence(:id) {|n| "model_solution_#{n}" }
    sequence(:files) {|n| build_list(:task_file, 1, id: "model_solution_file_#{n}") }

    trait(:populated) do
      description { 'description' }
      internal_description { 'internal_description' }
      files { build_list(:task_file, 1, :populated, :small_content, :text) }
    end

    trait(:with_multiple_files) do
      files { build_list(:task_file, 2, :populated, :small_content, :text) }
    end
  end
end
