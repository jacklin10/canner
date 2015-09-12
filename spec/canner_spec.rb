require "spec_helper"
require "canner"

class Sample
end

class SamplePolicy < Canner::Policy

  def initialize(current_user, method, current_branch)
    @current_user = current_user
    @current_branch = current_branch
    @method = method.to_sym
    @roles = fetch_roles
  end

  def fetch_roles
    ['admin']
  end

  def canner_scope
    [Sample.new]
  end

  def can?
   case @method
   when :index, :show
     has_role?(:admin)
   else
     false
   end
  end
end

class AppController
  include Canner

  attr_reader :current_user, :current_branch, :params
end

describe Canner do
  let(:user) { double }
  let(:branch) { double }
  let(:app_controller) { AppController.new }
  let(:sample_policy) {SamplePolicy.new(user, 'index', branch) }

  describe "instance_can?" do

    it "should call the policy's instance_can method" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:instance_can?).and_return true

      app_controller.instance_can?('test', 'sample', Sample.new)
    end

    it "should raise a NotAuthorizedError if the policy's instance_can? returns false" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:instance_can?).and_return false

      expect { app_controller.instance_can?('test', 'sample', Sample.new) }.to raise_error(Canner::NotAuthorizedError)
    end

    it "should return true if the policy allows access to the instance" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:instance_can?).and_return true

      expect(app_controller.instance_can?('test', 'sample', Sample.new)).to be true
    end

  end

  describe "can?" do

    it "should call the policy's can? method" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:can?).and_return true

      app_controller.can?('test', 'sample')
    end

    it "should raise a NotAuthorized error if the policy's can? returns false" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:can?).and_return false

      expect { app_controller.can?('test', 'sample') }.to raise_error(Canner::NotAuthorizedError)
    end

    it "should return true if the policy's can? permits access" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:can?).and_return true

      expect(app_controller.can?('test', 'sample')).to eq true
    end

  end

  describe "canner_scope" do

    it "should call the policy's canner_scope" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:canner_scope)

      app_controller.canner_scope('test', 'sample')
    end

  end

  describe "ensure_scope" do

    it "should not raise an error if canner_scope was called" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:canner_scope).and_return(true)
      app_controller.canner_scope('test', 'sample')

      expect(app_controller.send(:ensure_scope)).to be_truthy
    end

    it "should raise error if canner_scope was not called" do
      expect { app_controller.send(:ensure_scope) }.to raise_error(Canner::ScopeNotUsedError)
    end

  end

  describe "ensure_auth" do

    it "should not raise an error if can? was called" do
      expect(app_controller).to receive(:canner_policy).and_return(sample_policy)
      expect(sample_policy).to receive(:can?).and_return(true)
      app_controller.can?('test', 'sample')

      expect(app_controller.send(:ensure_auth)).to be_truthy
    end

    it "should raise error if can? was not called" do
      expect { app_controller.send(:ensure_auth) }.to raise_error(Canner::AuthNotUsedError)
    end

  end

  describe "canner_policy" do

    it "should instantiate the proper policy class" do
      expect(app_controller).to receive(:canner_user).and_return user
      expect(app_controller).to receive(:canner_branch).and_return branch

      expect(app_controller.send(:canner_policy, 'test', 'sample')).to be_a SamplePolicy
    end

  end

  describe "derive_class_name" do

    it "should return the proper policy class name from the model" do
      expect(app_controller.send(:derive_class_name, 'sample')).to eq "SamplePolicy"
      expect(app_controller.send(:derive_class_name, 'samples')).to eq "SamplePolicy"
    end

  end

end
