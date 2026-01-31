# frozen_string_literal: true

RSpec.describe "Authentication Integration", type: :graphql do
  describe "customer authentication flow" do
    it "allows signup and authenticated operations" do
      # Step 1: Customer signs up
      signup_query = <<~GQL
        mutation SignUp($email: String!, $name: String!, $password: String!, $passwordConfirmation: String!) {
          signUp(email: $email, name: $name, password: $password, passwordConfirmation: $passwordConfirmation) {
            customer { id email name }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: signup_query,
        variables: {
          email: "newuser@example.com",
          name: "New User",
          password: "password123",
          passwordConfirmation: "password123",
        },
      )

      expect(result.dig("data", "signUp", "customer", "email")).to eq("newuser@example.com")
      expect(response_cookies["access_token"]).to be_present
      expect(response_cookies["refresh_token"]).to be_present

      # Get customer from database
      customer = Customer.find_by(email: "newuser@example.com")
      expect(customer).to be_present

      # Step 2: Customer can create a ticket when authenticated
      create_ticket_query = <<~GQL
        mutation CreateTicket($subject: String!, $description: String!) {
          createTicket(subject: $subject, description: $description) {
            ticket { id subject }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: create_ticket_query,
        variables: { subject: "Test ticket", description: "Test description" },
        context: { current_user: customer },
      )

      expect(result.dig("data", "createTicket", "ticket", "subject")).to eq("Test ticket")
    end

    it "allows existing customer to sign in" do
      create(:customer, email: "existing@example.com", password: "password123",
                        password_confirmation: "password123",)

      signin_query = <<~GQL
        mutation SignIn($email: String!, $password: String!, $userType: String) {
          signIn(email: $email, password: $password, userType: $userType) {
            user { ... on Customer { id email } }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: signin_query,
        variables: { email: "existing@example.com", password: "password123", userType: "customer" },
      )

      expect(result.dig("data", "signIn", "user", "email")).to eq("existing@example.com")
      expect(response_cookies["access_token"]).to be_present
    end

    it "rejects invalid credentials" do
      create(:customer, email: "user@example.com", password: "correctpassword",
                        password_confirmation: "correctpassword",)

      signin_query = <<~GQL
        mutation SignIn($email: String!, $password: String!, $userType: String) {
          signIn(email: $email, password: $password, userType: $userType) {
            user { ... on Customer { id email } }
            errors { field message code }
          }
        }
      GQL

      result = execute_graphql(
        query: signin_query,
        variables: { email: "user@example.com", password: "wrongpassword", userType: "customer" },
      )

      expect(result.dig("data", "signIn", "user")).to be_nil
      expect(result.dig("data", "signIn", "errors")).not_to be_empty
      expect(response_cookies["access_token"]).to be_nil
    end
  end

  describe "agent authentication flow" do
    let(:admin) { create(:agent, :admin) }

    it "allows admin to invite agent" do
      # Admin invites new agent
      invite_query = <<~GQL
        mutation InviteAgent($email: String!, $name: String!, $isAdmin: Boolean) {
          inviteAgent(email: $email, name: $name, isAdmin: $isAdmin) {
            agent { id email name }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: invite_query,
        variables: { email: "newagent@company.com", name: "New Agent", isAdmin: false },
        context: { current_user: admin, current_agent: admin },
      )

      agent_data = result.dig("data", "inviteAgent", "agent")
      expect(agent_data["email"]).to eq("newagent@company.com")
      expect(agent_data["name"]).to eq("New Agent")

      # Verify agent was created
      new_agent = Agent.find_by(email: "newagent@company.com")
      expect(new_agent).to be_present
      expect(new_agent.invitation_token).to be_present
    end
  end

  describe "password reset flow" do
    let(:customer) { create(:customer, email: "reset@example.com") }

    it "allows customer to request password reset" do
      # Step 1: Request password reset
      request_reset_query = <<~GQL
        mutation RequestPasswordReset($email: String!) {
          requestPasswordReset(email: $email) {
            success
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: request_reset_query,
        variables: { email: "reset@example.com" },
      )

      expect(result.dig("data", "requestPasswordReset", "success")).to be true
    end
  end

  describe "authorization boundaries" do
    let(:customer) { create(:customer) }
    let(:agent) { create(:agent) }
    let(:other_customer) { create(:customer) }

    it "prevents customer from accessing other customer's tickets" do
      ticket = create(:ticket, customer: other_customer)

      ticket_query = <<~GQL
        query Ticket($id: ID!) {
          ticket(id: $id) { id subject }
        }
      GQL

      result = execute_graphql(
        query: ticket_query,
        variables: { id: ticket.id },
        context: { current_user: customer },
      )

      expect(result["errors"].first["message"]).to eq("Not authorized")
    end

    it "prevents customer from using agent mutations" do
      ticket = create(:ticket, customer: customer, assigned_agent: agent)

      transition_query = <<~GQL
        mutation TransitionTicket($ticketId: ID!, $event: String!) {
          transitionTicket(ticketId: $ticketId, event: $event) {
            ticket { id status }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: transition_query,
        variables: { ticketId: ticket.id, event: "close" },
        context: { current_user: customer },
      )

      data = result["data"]["transitionTicket"]
      expect(data["errors"].first["message"]).to eq("Not authorized")
    end

    it "prevents regular agent from inviting other agents" do
      invite_query = <<~GQL
        mutation InviteAgent($email: String!, $name: String!) {
          inviteAgent(email: $email, name: $name) {
            agent { id }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: invite_query,
        variables: { email: "test@company.com", name: "Test Agent" },
        context: { current_user: agent, current_agent: agent },
      )

      # Error returned as mutation error, not GraphQL error
      mutation_errors = result.dig("data", "inviteAgent", "errors")
      expect(mutation_errors.first["message"]).to eq("Admin access required")
      expect(result.dig("data", "inviteAgent", "agent")).to be_nil
    end
  end
end
