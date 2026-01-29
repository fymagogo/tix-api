# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    ticket
    author factory: [:agent]
    body { "This is a test comment." }
  end
end
