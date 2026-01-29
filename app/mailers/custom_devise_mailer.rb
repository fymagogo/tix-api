# frozen_string_literal: true

class CustomDeviseMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers
  default template_path: "devise/mailer"

  def reset_password_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @frontend_url = build_frontend_reset_url(record, token)
    
    opts[:subject] = "Reset password instructions"
    devise_mail(record, :reset_password_instructions, opts)
  end

  def invitation_instructions(record, token, opts = {})
    @token = token
    @resource = record
    @frontend_url = build_frontend_invite_url(record, token)
    
    opts[:subject] = "You've been invited to join Tix"
    devise_mail(record, :invitation_instructions, opts)
  end

  private

  def build_frontend_reset_url(record, token)
    base_url = frontend_base_url(record)
    "#{base_url}/reset-password?token=#{token}"
  end

  def build_frontend_invite_url(record, token)
    base_url = frontend_base_url(record)
    "#{base_url}/accept-invite?token=#{token}"
  end

  def frontend_base_url(record)
    if record.is_a?(Customer)
      ENV.fetch("CUSTOMER_PORTAL_URL", "http://localhost:5173")
    else
      ENV.fetch("AGENT_PORTAL_URL", "http://localhost:5174")
    end
  end
end
