# frozen_string_literal: true

FactoryBot.define do
  factory :ticket do
    customer
    sequence(:subject) { |n| "Test Ticket #{n}" }
    description { "This is a test ticket description." }
    status { "new" }

    trait :with_agent do
      assigned_agent factory: [:agent]
      status { "agent_assigned" }
    end

    trait :in_progress do
      with_agent
      status { "in_progress" }
    end

    trait :on_hold do
      with_agent
      status { "hold" }
    end

    trait :closed do
      with_agent
      status { "closed" }
      closed_at { Time.current }
    end
  end
end
