# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create admin agent
admin = Agent.find_or_create_by!(email: "admin@tix.test") do |a|
  a.name = "Admin User"
  a.password = "password123"
  a.password_confirmation = "password123"
  a.is_admin = true
  a.invitation_accepted_at = Time.current
end
puts "Created admin agent: #{admin.email}"

# Create regular agents
agents = []
3.times do |i|
  agent = Agent.find_or_create_by!(email: "agent#{i + 1}@tix.test") do |a|
    a.name = "Agent #{i + 1}"
    a.password = "password123"
    a.password_confirmation = "password123"
    a.is_admin = false
    a.invitation_accepted_at = Time.current
    a.invited_by = admin
  end
  agents << agent
  puts "Created agent: #{agent.email}"
end

# Create customers
customers = []
5.times do |i|
  customer = Customer.find_or_create_by!(email: "customer#{i + 1}@example.com") do |c|
    c.name = "Customer #{i + 1}"
    c.password = "password123"
    c.password_confirmation = "password123"
  end
  customers << customer
  puts "Created customer: #{customer.email}"
end

# Create sample tickets with various statuses
ticket_data = [
  { subject: "Can't login to my account", description: "I'm getting an error when trying to login. Please help!", status: :new },
  { subject: "Billing question", description: "I was charged twice last month. Can you check my account?", status: :agent_assigned },
  { subject: "Feature request: Dark mode", description: "Would love to have a dark mode option in the app.", status: :in_progress },
  { subject: "App crashes on startup", description: "Since the last update, the app crashes immediately when I open it.", status: :hold },
  { subject: "How to export data?", description: "I need to export my data for a report. How do I do this?", status: :closed },
  { subject: "Password reset not working", description: "I'm not receiving the password reset email.", status: :new },
  { subject: "API rate limits", description: "What are the current API rate limits for the pro plan?", status: :in_progress },
  { subject: "Integration with Slack", description: "Is there a Slack integration available?", status: :closed },
]

ticket_data.each_with_index do |data, i|
  customer = customers[i % customers.length]
  agent = agents[i % agents.length]

  ticket = Ticket.find_or_create_by!(subject: data[:subject], customer: customer) do |t|
    t.description = data[:description]
  end

  # Transition to the desired status
  case data[:status]
  when :agent_assigned
    ticket.update!(assigned_agent: agent)
    ticket.assign_agent! if ticket.may_assign_agent?
  when :in_progress
    ticket.update!(assigned_agent: agent)
    ticket.assign_agent! if ticket.may_assign_agent?
    ticket.start_progress! if ticket.may_start_progress?
  when :hold
    ticket.update!(assigned_agent: agent)
    ticket.assign_agent! if ticket.may_assign_agent?
    ticket.start_progress! if ticket.may_start_progress?
    ticket.put_on_hold! if ticket.may_put_on_hold?
  when :closed
    ticket.update!(assigned_agent: agent)
    ticket.assign_agent! if ticket.may_assign_agent?
    ticket.start_progress! if ticket.may_start_progress?
    ticket.close! if ticket.may_close?
  end

  puts "Created ticket: #{ticket.subject} (#{ticket.status})"

  # Add some sample comments
  if ticket.assigned_agent.present?
    Comment.find_or_create_by!(ticket: ticket, author: ticket.assigned_agent, body: "Thanks for reaching out! I'm looking into this now.")
    Comment.find_or_create_by!(ticket: ticket, author: customer, body: "Thank you for the quick response!")
  end
end

puts "\n✅ Seed completed!"
puts "\nTest accounts:"
puts "  Admin: admin@tix.test / password123"
puts "  Agents: agent1@tix.test, agent2@tix.test, agent3@tix.test / password123"
puts "  Customers: customer1@example.com - customer5@example.com / password123"
