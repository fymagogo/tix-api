# frozen_string_literal: true

module Resolvers
  class TicketsResolver < Resolvers::BaseResolver
    type Types::Pages::TicketPageType, null: false
    description "List tickets with pagination, filtering, and sorting"

    argument :pagination, Types::Inputs::PaginationInputType, required: false, default_value: {}
    argument :filter, Types::Inputs::TicketFilterInputType, required: false
    argument :order_by, Types::Inputs::TicketOrderByInputType, required: false

    def resolve(pagination:, filter: nil, order_by: nil)
      authorize_record(Ticket, :index?)

      scope = policy_scope(Ticket)
      scope = apply_eager_loading(scope)
      scope = apply_filters(scope, filter) if filter
      scope = apply_ordering(scope, order_by)

      paginated = scope.page(pagination[:page]).per(pagination[:per_page])

      {
        items: paginated,
        page_info: build_page_info(paginated)
      }
    end

    private

    def apply_eager_loading(scope)
      scope.includes(:customer, :assigned_agent, :comments, attachments_attachments: :blob)
    end

    def apply_filters(scope, filter)
      scope = scope.where(status: filter[:status]) if filter[:status].present?
      scope = scope.where(assigned_agent_id: context[:current_user].id) if filter[:assigned_to_me]
      scope = scope.where(customer_id: filter[:customer_id]) if filter[:customer_id].present?
      if filter[:search].present?
        # Sanitize and limit search input
        search_term = filter[:search].to_s.strip[0, 100]
        search_term = ActiveRecord::Base.sanitize_sql_like(search_term)
        scope = scope.where("subject ILIKE :q OR ticket_number ILIKE :q", q: "%#{search_term}%")
      end
      scope = scope.where("created_at >= ?", filter[:created_after]) if filter[:created_after].present?
      scope = scope.where("created_at <= ?", filter[:created_before]) if filter[:created_before].present?
      scope
    end

    def apply_ordering(scope, order_by)
      return scope.order(updated_at: :desc) unless order_by

      scope.order(order_by[:field] => order_by[:direction])
    end

    def build_page_info(paginated)
      {
        current_page: paginated.current_page,
        total_pages: paginated.total_pages,
        total_count: paginated.total_count,
        has_next_page: !paginated.last_page?,
        has_previous_page: !paginated.first_page?,
        per_page: paginated.limit_value
      }
    end

    def authorize_record(record, action)
      policy = Pundit.policy!(context[:current_user], record)
      raise Pundit::NotAuthorizedError unless policy.public_send(action)
    end

    def policy_scope(klass)
      Pundit.policy_scope!(context[:current_user], klass)
    end
  end
end
