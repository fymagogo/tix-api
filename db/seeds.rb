# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Rails.logger.debug "Seeding database..."

# Create admin agent
admin = Agent.find_or_create_by!(email: "admin@tix.test") do |a|
  a.name = "Admin User"
  a.password = "password123"
  a.password_confirmation = "password123"
  a.is_admin = true
  a.invitation_accepted_at = Time.current
end
Rails.logger.debug { "Created admin agent: #{admin.email}" }

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
  Rails.logger.debug { "Created agent: #{agent.email}" }
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
  Rails.logger.debug { "Created customer: #{customer.email}" }
end

Rails.logger.debug "\n✅ Seed completed!"
Rails.logger.debug "\nTest accounts:"
Rails.logger.debug "  Admin: admin@tix.test / password123"
Rails.logger.debug "  Agents: agent1@tix.test, agent2@tix.test, agent3@tix.test / password123"
Rails.logger.debug "  Customers: customer1@example.com - customer5@example.com / password123"
