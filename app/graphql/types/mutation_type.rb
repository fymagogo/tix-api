# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    # Auth mutations
    field :request_password_reset, mutation: Mutations::RequestPasswordReset
    field :reset_password, mutation: Mutations::ResetPassword
    field :sign_in, mutation: Mutations::SignIn
    field :sign_up, mutation: Mutations::SignUp

    # Agent invitation mutations
    field :accept_invite, mutation: Mutations::AcceptInvite
    field :invite_agent, mutation: Mutations::InviteAgent

    # Ticket mutations
    field :assign_ticket, mutation: Mutations::AssignTicket
    field :create_ticket, mutation: Mutations::CreateTicket
    field :transition_ticket, mutation: Mutations::TransitionTicket

    # Comment mutations
    field :add_comment, mutation: Mutations::AddComment

    # Export mutations
    field :export_closed_tickets, mutation: Mutations::ExportClosedTickets

    # File upload mutations
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload
  end
end
