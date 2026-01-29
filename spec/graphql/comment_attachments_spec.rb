require 'rails_helper'

RSpec.describe 'Comment Attachments', type: :graphql do
  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }
  let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent, status: 'in_progress') }

  describe 'adding a comment with attachments' do
    let(:mutation) do
      <<~GQL
        mutation AddComment($ticketId: ID!, $body: String!, $attachmentIds: [String!]) {
          addComment(ticketId: $ticketId, body: $body, attachmentIds: $attachmentIds) {
            comment {
              id
              body
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
        io: StringIO.new('screenshot content'),
        filename: 'screenshot.png',
        content_type: 'image/png'
      )
    end

    context 'as an agent' do
      it 'creates a comment with attachments' do
        signed_id = blob.signed_id

        result = execute_graphql(
          query: mutation,
          variables: {
            ticketId: ticket.id,
            body: 'Here is a screenshot showing the issue',
            attachmentIds: [signed_id]
          },
          context: { current_user: agent }
        )

        data = result.dig('data', 'addComment')
        expect(data['errors']).to be_empty
        expect(data['comment']).to be_present
        expect(data['comment']['attachments'].length).to eq(1)
        expect(data['comment']['attachments'].first['filename']).to eq('screenshot.png')
      end
    end

    context 'as a customer' do
      before do
        # Customer can comment after agent has responded
        ticket.comments.create!(body: 'Agent response', author: agent)
      end

      it 'creates a comment with attachments' do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('customer file'),
          filename: 'document.pdf',
          content_type: 'application/pdf'
        )

        result = execute_graphql(
          query: mutation,
          variables: {
            ticketId: ticket.id,
            body: 'Here is the document you requested',
            attachmentIds: [blob.signed_id]
          },
          context: { current_user: customer }
        )

        data = result.dig('data', 'addComment')
        expect(data['errors']).to be_empty
        expect(data['comment']).to be_present
        expect(data['comment']['attachments'].length).to eq(1)
        expect(data['comment']['attachments'].first['filename']).to eq('document.pdf')
      end
    end
  end

  describe 'querying comment attachments' do
    let(:comment) { create(:comment, ticket: ticket, author: agent) }

    let(:query) do
      <<~GQL
        query Ticket($id: ID!) {
          ticket(id: $id) {
            comments {
              id
              body
              attachments {
                id
                filename
                contentType
                byteSize
                url
              }
            }
          }
        }
      GQL
    end

    before do
      comment.attachments.attach(
        io: StringIO.new('file content'),
        filename: 'response.png',
        content_type: 'image/png'
      )
    end

    it 'returns comment attachments' do
      result = execute_graphql(
        query: query,
        variables: { id: ticket.id },
        context: { current_user: customer }
      )

      comments = result.dig('data', 'ticket', 'comments')
      comment_with_attachment = comments.find { |c| c['attachments'].present? }
      expect(comment_with_attachment).to be_present
      expect(comment_with_attachment['attachments'].first['filename']).to eq('response.png')
      expect(comment_with_attachment['attachments'].first['url']).to be_present
    end
  end
end
