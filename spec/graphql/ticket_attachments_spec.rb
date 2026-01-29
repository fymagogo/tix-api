require 'rails_helper'

RSpec.describe 'Ticket Attachments', type: :graphql do
  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }

  describe 'creating a ticket with attachments' do
    let(:mutation) do
      <<~GQL
        mutation CreateTicket($subject: String!, $description: String!, $attachmentIds: [String!]) {
          createTicket(subject: $subject, description: $description, attachmentIds: $attachmentIds) {
            ticket {
              id
              subject
              attachments {
                id
                filename
                contentType
              }
            }
            errors {
              field
              message
            }
          }
        }
      GQL
    end

    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('test content'),
        filename: 'test.png',
        content_type: 'image/png'
      )
    end

    it 'creates a ticket with attachments' do
      signed_id = blob.signed_id

      result = execute_graphql(
        query: mutation,
        variables: {
          subject: 'Test ticket with attachment',
          description: 'This ticket has an attachment for testing',
          attachmentIds: [signed_id]
        },
        context: { current_user: customer }
      )

      data = result.dig('data', 'createTicket')
      expect(data['errors']).to be_empty
      expect(data['ticket']).to be_present
      expect(data['ticket']['attachments'].length).to eq(1)
      expect(data['ticket']['attachments'].first['filename']).to eq('test.png')
    end

    it 'creates a ticket without attachments' do
      result = execute_graphql(
        query: mutation,
        variables: {
          subject: 'Test ticket without attachment',
          description: 'This ticket has no attachments'
        },
        context: { current_user: customer }
      )

      data = result.dig('data', 'createTicket')
      expect(data['errors']).to be_empty
      expect(data['ticket']).to be_present
      expect(data['ticket']['attachments']).to be_empty
    end
  end

  describe 'querying ticket attachments' do
    let(:ticket) { create(:ticket, customer: customer) }
    
    let(:query) do
      <<~GQL
        query Ticket($id: ID!) {
          ticket(id: $id) {
            id
            attachments {
              id
              filename
              contentType
              byteSize
              url
            }
          }
        }
      GQL
    end

    before do
      ticket.attachments.attach(
        io: StringIO.new('test content'),
        filename: 'test-attachment.pdf',
        content_type: 'application/pdf'
      )
    end

    it 'returns ticket attachments' do
      result = execute_graphql(
        query: query,
        variables: { id: ticket.id },
        context: { current_user: customer }
      )

      data = result.dig('data', 'ticket')
      expect(data['attachments'].length).to eq(1)
      expect(data['attachments'].first['filename']).to eq('test-attachment.pdf')
      expect(data['attachments'].first['contentType']).to eq('application/pdf')
      expect(data['attachments'].first['url']).to be_present
    end
  end
end
