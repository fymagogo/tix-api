# frozen_string_literal: true

RSpec.describe RefreshToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:refresh_token) }

    it { is_expected.to validate_presence_of(:token_digest) }
    it { is_expected.to validate_uniqueness_of(:token_digest) }
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  describe ".generate_for" do
    let(:customer) { create(:customer) }

    it "creates a new refresh token record" do
      expect { RefreshToken.generate_for(customer) }.to change(RefreshToken, :count).by(1)
    end

    it "returns record and raw token" do
      record, raw_token = RefreshToken.generate_for(customer)

      expect(record).to be_persisted
      expect(raw_token).to be_present
      expect(raw_token.length).to be > 20
    end

    it "stores hashed token, not raw token" do
      record, raw_token = RefreshToken.generate_for(customer)

      expect(record.token_digest).not_to eq(raw_token)
      expect(record.token_digest).to eq(RefreshToken.digest(raw_token))
    end

    it "sets expiry to 7 days from now" do
      record, _raw_token = RefreshToken.generate_for(customer)

      expect(record.expires_at).to be_within(1.minute).of(7.days.from_now)
    end
  end

  describe ".find_by_token" do
    let(:customer) { create(:customer) }
    let!(:token_pair) { RefreshToken.generate_for(customer) }
    let(:raw_token) { token_pair.last }

    it "finds token by raw value" do
      found = RefreshToken.find_by_token(raw_token)

      expect(found).to eq(token_pair.first)
    end

    it "returns nil for invalid token" do
      found = RefreshToken.find_by_token("invalid_token")

      expect(found).to be_nil
    end

    it "returns nil for expired token" do
      token_pair.first.update!(expires_at: 1.day.ago)

      found = RefreshToken.find_by_token(raw_token)

      expect(found).to be_nil
    end

    it "returns nil for revoked token" do
      token_pair.first.revoke!

      found = RefreshToken.find_by_token(raw_token)

      expect(found).to be_nil
    end
  end

  describe "#revoke!" do
    let(:customer) { create(:customer) }
    let!(:token_pair) { RefreshToken.generate_for(customer) }

    it "sets revoked_at" do
      token_pair.first.revoke!

      expect(token_pair.first.revoked_at).to be_present
    end

    it "makes token invalid" do
      token_pair.first.revoke!

      expect(token_pair.first.valid_token?).to be false
    end
  end

  describe "#rotate!" do
    let(:customer) { create(:customer) }
    let!(:original_pair) { RefreshToken.generate_for(customer) }

    it "revokes old token and creates new one" do
      new_record, new_raw_token = original_pair.first.rotate!

      expect(original_pair.first.revoked?).to be true
      expect(new_record).to be_persisted
      expect(new_raw_token).to be_present
      expect(new_record.user).to eq(customer)
    end
  end

  describe ".cleanup_expired!" do
    let(:customer) { create(:customer) }

    before do
      # Create various tokens
      @active_token = RefreshToken.generate_for(customer).first
      @recently_expired = RefreshToken.generate_for(customer).first.tap do |t|
        t.update!(expires_at: 1.day.ago)
      end
      @old_expired = RefreshToken.generate_for(customer).first.tap do |t|
        t.update!(expires_at: 2.months.ago, created_at: 2.months.ago)
      end
    end

    it "deletes old expired tokens" do
      expect { RefreshToken.cleanup_expired! }.to change(RefreshToken, :count).by(-1)
    end

    it "keeps active tokens" do
      RefreshToken.cleanup_expired!

      expect(@active_token.reload).to be_present
    end

    it "keeps recently expired tokens" do
      RefreshToken.cleanup_expired!

      expect(@recently_expired.reload).to be_present
    end
  end
end
