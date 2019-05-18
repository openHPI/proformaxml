# frozen_string_literal: true

FactoryBot.define do
  factory :model_solution, class: Proforma::ModelSolution do
    trait(:populated) do
      id { 'id' }
      description { 'description' }
      internal_description { 'internal_description' }
      files { build_list(:task_file, 1, :populated, :small_content, :text) }
    end
  end
end
