# frozen_string_literal: true

RSpec.describe "ticketByNumber", type: :graphql do
  let(:query) do
    <<~GQL
      query TicketByNumber($ticketNumber: String!) {
        ticketByNumber(ticketNumber: $ticketNumber) {
          id
          ticketNumber
          subject
        }
      }
    GQL
  end

  it "returns the ticket for the owning customer" do
    customer = create(:customer)
    ticket = create(:ticket, customer: customer)

    @graphql_response = execute_graphql(
      query: query,
      variables: { ticketNumber: ticket.ticket_number },
      context: { current_user: customer },
    ).to_h

    expect(graphql_errors).to be_nil
    expect(graphql_data.dig("ticketByNumber", "id")).to eq(ticket.id)
    expect(graphql_data.dig("ticketByNumber", "ticketNumber")).to eq(ticket.ticket_number)
  end

  it "returns null for a different customer (no existence leak)" do
    owner = create(:customer)
    other = create(:customer)
    ticket = create(:ticket, customer: owner)

    @graphql_response = execute_graphql(
      query: query,
      variables: { ticketNumber: ticket.ticket_number },
      context: { current_user: other },
    ).to_h

    expect(graphql_errors).to be_nil
    expect(graphql_data["ticketByNumber"]).to be_nil
  end
end
