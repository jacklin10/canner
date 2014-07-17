# ASSUMES that your permissions policy is in a file with the same name as your model but with Perm.
# i.e UserPerm, CustomerPerm
module Canner

  # so you don't have to have a helper method in the app_controller
  def self.included(c)
    c.helper_method :canner_policy
  end

  class NotAuthorizedError < StandardError
    attr_accessor :role, :method
  end

  class AuthNotUsedError < StandardError; end
  class ScopeNotUsedError < StandardError; end

  # method_name - The controller action method that you are concerned with access
  # target_model - Name of the object you are limiting access to. ( :user, :pet, :customer )
  # target_obj   - The instance obj for what you want to test.  ( does user 1 have access to company 1?)
  def instance_can?(method_name, target_model, target_obj)
    policy = canner_policy(method_name, target_model)
    raise NotAuthorizedError.new("You do not have access to this #{target_model.capitalize}") unless policy.instance_can?(target_obj)
  end

  # method_name - The controller action method that you are concerned with access
  # target_model - Name of the object you are limiting access to. ( :user, :pet, :customer )
  def can?(method_name, target_model)
    @auth_used = true
    raise NotAuthorizedError.new("You are not authorized to perform this action.") unless canner_policy(method_name, target_model).can?
  end

  # method_name - The controller action method that you are concerned with access
  # target_model - Name of the object you are limiting access to. ( :user, :pet, :customer )
  def canner_scope(method_name, target_model)
    @scope_used = true
    canner_policy(method_name, target_model).canner_scope
  end

  protected

  def ensure_scope
    return if devise_controller? rescue false
    raise ScopeNotUsedError.new("Must use a canner_scope or exclude this action from the after_action") unless @scope_used
  end

  def ensure_auth
    return if devise_controller? rescue false
    raise AuthNotUsedError.new("Must use can? method or exclude this action from the after_action") unless @auth_used
  end

  def canner_policy(method_name, target_model)
    derive_class_name(target_model).constantize.new(current_user, current_branch, method_name)
  end

  def derive_class_name(target_model)
    "#{target_model.to_s.classify}Policy"
  end

end
