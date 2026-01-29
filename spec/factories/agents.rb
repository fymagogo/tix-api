# frozen_string_literal: true

FactoryBot.define do
  factory :agent do
    sequence(:email) { |n| "agent#{n}@tix.test" }
    sequence(:name) { |n| "Agent #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    is_admin { false }
    invitation_accepted_at { Time.current }

    trait :admin do
      is_admin { true }
    end
  end
end
