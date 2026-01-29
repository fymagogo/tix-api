# frozen_string_literal: true

RSpec.describe "Statistics and Dashboard Integration", type: :graphql do
  let(:agent) { create(:agent) }
  let(:other_agent) { create(:agent) }
  let(:admin) { create(:agent, :admin) }
  let(:customer) { create(:customer) }

  describe "dashboard statistics" do
    before do
      # Create tickets in various states
      create_list(:ticket, 3, customer: customer) # new
      create_list(:ticket, 2, :with_agent, customer: customer, assigned_agent: agent) # agent_assigned
      create_list(:ticket, 4, :in_progress, customer: customer, assigned_agent: agent) # in_progress
      create_list(:ticket, 1, :on_hold, customer: customer, assigned_agent: agent) # hold
      create_list(:ticket, 5, :closed, customer: customer, assigned_agent: agent) # closed
    end

    it "returns correct dashboard statistics for admin" do
      stats_query = <<~GQL
        query DashboardStats {
          dashboardStats {
            totalTickets
            openTickets
            closedTickets
            unassignedTickets
            ticketsByStatus { status count }
          }
        }
      GQL

      result = execute_graphql(
        query: stats_query,
        context: { current_user: admin, current_agent: admin }
      )

      stats = result.dig("data", "dashboardStats")
      expect(stats["totalTickets"]).to eq(15)
      expect(stats["closedTickets"]).to eq(5)
      expect(stats["unassignedTickets"]).to eq(3)

      # Verify status breakdown
      by_status = stats["ticketsByStatus"].to_h { |s| [s["status"], s["count"]] }
      expect(by_status["new"]).to eq(3)
      expect(by_status["in_progress"]).to eq(4)
      expect(by_status["closed"]).to eq(5)
    end

    it "prevents non-admin agents from viewing dashboard stats" do
      stats_query = <<~GQL
        query DashboardStats {
          dashboardStats {
            totalTickets
          }
        }
      GQL

      result = execute_graphql(
        query: stats_query,
        context: { current_user: agent, current_agent: agent }
      )

      expect(result["errors"].first["message"]).to eq("Not authorized")
    end

    it "prevents customers from viewing dashboard stats" do
      stats_query = <<~GQL
        query DashboardStats {
          dashboardStats {
            totalTickets
          }
        }
      GQL

      result = execute_graphql(
        query: stats_query,
        context: { current_user: customer }
      )

      expect(result["errors"].first["message"]).to eq("Not authorized")
    end
  end

  describe "agent statistics" do
    before do
      # Agent's tickets
      create_list(:ticket, 2, :in_progress, assigned_agent: agent, customer: customer)
      create_list(:ticket, 3, :closed, assigned_agent: agent, customer: customer)
      create_list(:ticket, 1, :on_hold, assigned_agent: agent, customer: customer)

      # Other agent's tickets
      create_list(:ticket, 5, :closed, assigned_agent: other_agent, customer: customer)
    end

    it "returns correct stats for current agent" do
      agent_stats_query = <<~GQL
        query AgentStats {
          agentStats {
            agent { id name }
            assignedTickets
            closedTickets
          }
        }
      GQL

      result = execute_graphql(
        query: agent_stats_query,
        context: { current_user: agent, current_agent: agent }
      )

      stats = result.dig("data", "agentStats")
      expect(stats["agent"]["id"]).to eq(agent.id)
      expect(stats["assignedTickets"]).to eq(6)
      expect(stats["closedTickets"]).to eq(3)
    end

    it "allows admin to view specific agent's stats" do
      agent_stats_query = <<~GQL
        query AgentStats($agentId: ID!) {
          agentStats(agentId: $agentId) {
            agent { id }
            assignedTickets
            closedTickets
          }
        }
      GQL

      result = execute_graphql(
        query: agent_stats_query,
        variables: { agentId: other_agent.id },
        context: { current_user: admin, current_agent: admin }
      )

      stats = result.dig("data", "agentStats")
      expect(stats["agent"]["id"]).to eq(other_agent.id)
      expect(stats["closedTickets"]).to eq(5)
    end

    it "prevents regular agent from viewing other agent's stats" do
      agent_stats_query = <<~GQL
        query AgentStats($agentId: ID!) {
          agentStats(agentId: $agentId) {
            agent { id }
          }
        }
      GQL

      result = execute_graphql(
        query: agent_stats_query,
        variables: { agentId: other_agent.id },
        context: { current_user: agent, current_agent: agent }
      )

      expect(result["errors"].first["message"]).to include("Not authorized")
    end
  end

  describe "all agents statistics (admin only)" do
    before do
      create_list(:ticket, 3, :closed, assigned_agent: agent, customer: customer)
      create_list(:ticket, 5, :closed, assigned_agent: other_agent, customer: customer)
      create_list(:ticket, 2, :in_progress, assigned_agent: agent, customer: customer)
    end

    it "returns stats for all agents when requested by admin" do
      all_stats_query = <<~GQL
        query AllAgentsStats {
          allAgentsStats {
            agent { id name }
            assignedTickets
            closedTickets
          }
        }
      GQL

      result = execute_graphql(
        query: all_stats_query,
        context: { current_user: admin, current_agent: admin }
      )

      all_stats = result.dig("data", "allAgentsStats")
      # 3 agents: agent, other_agent, and admin
      expect(all_stats.length).to eq(3)

      agent_stats = all_stats.find { |s| s["agent"]["id"] == agent.id.to_s }
      expect(agent_stats["closedTickets"]).to eq(3)
      expect(agent_stats["assignedTickets"]).to eq(5)

      other_stats = all_stats.find { |s| s["agent"]["id"] == other_agent.id.to_s }
      expect(other_stats["closedTickets"]).to eq(5)
    end

    it "prevents regular agent from viewing all agents stats" do
      all_stats_query = <<~GQL
        query AllAgentsStats {
          allAgentsStats {
            agent { id }
          }
        }
      GQL

      result = execute_graphql(
        query: all_stats_query,
        context: { current_user: agent, current_agent: agent }
      )

      expect(result["errors"].first["message"]).to eq("Not authorized")
    end
  end

  describe "statistics accuracy over time" do
    it "updates statistics correctly when tickets change state" do
      # Create initial ticket
      ticket = create(:ticket, :in_progress, customer: customer, assigned_agent: agent)

      transition_query = <<~GQL
        mutation TransitionTicket($ticketId: ID!, $event: String!) {
          transitionTicket(ticketId: $ticketId, event: $event) {
            ticket { id status }
          }
        }
      GQL

      agent_stats_query = <<~GQL
        query AgentStats {
          agentStats {
            assignedTickets
            openTickets
            closedTickets
          }
        }
      GQL

      # Check initial stats
      result = execute_graphql(query: agent_stats_query, context: { current_user: agent, current_agent: agent })
      initial_open = result.dig("data", "agentStats", "openTickets")
      initial_closed = result.dig("data", "agentStats", "closedTickets")

      # Close the ticket
      execute_graphql(
        query: transition_query,
        variables: { ticketId: ticket.id, event: "close" },
        context: { current_user: agent }
      )

      # Check updated stats
      result = execute_graphql(query: agent_stats_query, context: { current_user: agent, current_agent: agent })
      expect(result.dig("data", "agentStats", "openTickets")).to eq(initial_open - 1)
      expect(result.dig("data", "agentStats", "closedTickets")).to eq(initial_closed + 1)
    end
  end

  describe "pagination in ticket listings" do
    before do
      create_list(:ticket, 25, customer: customer, assigned_agent: agent)
    end

    it "supports offset-based pagination" do
      paginated_query = <<~GQL
        query Tickets($pagination: PaginationInput) {
          tickets(pagination: $pagination) {
            items { id }
            pageInfo {
              currentPage
              totalPages
              totalCount
              hasNextPage
            }
          }
        }
      GQL

      # First page
      result = execute_graphql(
        query: paginated_query,
        variables: { pagination: { page: 1, perPage: 10 } },
        context: { current_user: agent }
      )

      first_page = result.dig("data", "tickets")
      expect(first_page["items"].length).to eq(10)
      expect(first_page["pageInfo"]["totalCount"]).to eq(25)
      expect(first_page["pageInfo"]["hasNextPage"]).to be true

      # Second page
      result = execute_graphql(
        query: paginated_query,
        variables: { pagination: { page: 2, perPage: 10 } },
        context: { current_user: agent }
      )

      second_page = result.dig("data", "tickets")
      expect(second_page["items"].length).to eq(10)
      expect(second_page["pageInfo"]["hasNextPage"]).to be true

      # Third page (last)
      result = execute_graphql(
        query: paginated_query,
        variables: { pagination: { page: 3, perPage: 10 } },
        context: { current_user: agent }
      )

      third_page = result.dig("data", "tickets")
      expect(third_page["items"].length).to eq(5)
      expect(third_page["pageInfo"]["hasNextPage"]).to be false
    end
  end
end
