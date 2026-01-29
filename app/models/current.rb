# frozen_string_literal: true

# Used for Current.user tracking in audits and other places
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
