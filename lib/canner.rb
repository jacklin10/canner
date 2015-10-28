require 'active_support/core_ext/string'
require "active_support/concern"
require 'canner/policy'
require 'canner/util'

module Canner

  extend ActiveSupport::Concern

  # so you don't have to have a helper method in the app_controller
  included do
    if respond_to?(:helper_method)
      helper_method :canner_policy
      helper_method :canner_user
      helper_method :canner_branch
    end
  end

  class NotAuthorizedError < StandardError
    attr_accessor :role, :method
  end

  class AuthNotUsedError < StandardError; end
  class ScopeNotUsedError < StandardError; end
  class InstanceNotProtectedError < StandardError; end

  def auth_used
    @auth_used ||= false
  end

  def scope_used
    @scope_used ||= false
  end

  def instance_checked
    @instance_checked ||= false
  end

  # method_name - The controller action method that you are concerned with access
  # target_model - Name of the object you are limiting access to. ( :user, :pet, :customer )
  # target_obj   - The instance obj for what you want to test.  ( does user 1 have access to company 1?)
  def instance_can?(method_name, target_model, target_obj)
    @instance_checked = true
    policy = canner_policy(method_name, target_model)
    raise NotAuthorizedError.new("You do not have access to this #{target_model.to_s.humanize.capitalize}") unless policy.instance_can?(target_obj)
    true
  end

  # method_name - The controller action method that you are concerned with access
  # target_model - Name of the object you are limiting access to. ( :user, :pet, :customer )
  def can?(method_name, target_model)
    @auth_used = true
    raise NotAuthorizedError.new("You are not authorized to perform this action.") unless canner_policy(method_name, target_model).can?
    true
  end

  # method_name - The controller action method that you are concerned with access
  # target_model - Name of the object you are limiting access to. ( :user, :pet, :customer )
  def canner_scope(method_name, target_model)
    @scope_used = true
    canner_policy(method_name, target_model).canner_scope
  end

  # override this if your method for getting the current user isn't called current_user.
  def canner_user
    current_user
  end

  # override this if your method for getting the current branch isn't called current_branch.
  def canner_branch
    current_branch rescue nil
  end

  protected

  def ensure_scope
    raise ScopeNotUsedError.new("Must use a canner_scope or exclude this action from the after_action") unless scope_used
    true
  end

  def ensure_auth
    raise AuthNotUsedError.new("Must use can? method or exclude this action from the after_action") unless auth_used
    true
  end

  def ensure_instance_checking
    raise AuthNotUsedError.new("Must use instance_can? method or exclude this action from the after_action") unless instance_checked
    true
  end

  def canner_policy(method_name, target_model)
    derive_class_name(target_model).constantize.new(canner_user, method_name, canner_branch)
  end

  def derive_class_name(target_model)
    "#{target_model.to_s.classify}Policy"
  end

end
