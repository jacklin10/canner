require "spec_helper"

describe Canner::Policy do
  let(:admin_role) { instance_double('Role', name: 'admin') }
  let(:user_role) { instance_double('Role', name: 'user') }
  let(:user) { instance_double('User', roles: [admin_role, user_role]) }

  describe "fetch_roles" do
    it "should return an empty array is the user is nil" do
      policy = Canner::Policy.new(nil, 'index')
      expect(policy.fetch_roles).to eq([])
    end

    it 'should return the users roles' do
      policy = Canner::Policy.new(user, 'index')

      expect(policy.fetch_roles).to eq(user.roles)
    end
  end

  describe "has_role?" do
    it "should return true of the user has the role" do
      policy = Canner::Policy.new(user, 'index')
      expect(policy.has_role?([:admin])).to be_truthy
    end

    it 'should work with multiple roles' do
      policy = Canner::Policy.new(user, 'index')
      expect(policy.has_role?([:admin, :user])).to be_truthy
    end

    it 'should return true if the user has any of the roles' do
      policy = Canner::Policy.new(user, 'index')
      expect(policy.has_role?([:fake, :more_fake, :faker_still, :user])).to be_truthy
    end

    it "should return false if the user doesn't have the role" do
      policy = Canner::Policy.new(user, 'index')
      expect(policy.has_role?([:fake])).to be_falsy
    end

    it "should work with string" do
      policy = Canner::Policy.new(user, 'index')
      expect(policy.has_role?(['admin'])).to be_truthy
    end

    it "should work without an array as the param for one role." do
      policy = Canner::Policy.new(user, 'index')
      expect(policy.has_role?('admin')).to be_truthy

      policy = Canner::Policy.new(user, 'index')
      expect(policy.has_role?(:admin)).to be_truthy
    end
  end
end
