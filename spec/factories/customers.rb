# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    sequence(:email) { |n| "customer#{n}@example.com" }
    sequence(:name) { |n| "Customer #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
