# frozen_string_literal: true

RSpec.describe Customer do
  describe "validations" do
    subject { build(:customer) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe "associations" do
    it { is_expected.to have_many(:tickets).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  describe "#generate_jwt" do
    let(:customer) { create(:customer) }

    it "generates a valid JWT token" do
      token = customer.generate_jwt
      expect(token).to be_present
      expect(token).to be_a(String)
    end
  end
end
