module Canner

  class Policy

    # current_user - The user whose access you are checking
    # current_branch - The optional 3rd access checking item.
    #                  With branch you are saying can the user access this resource in this case.
    #                  For example, is Joe a manager at the Pittsburgh branch?
    #                  He may be a manager in Pittsburgh, but not in Monaca so you need to know the branch.
    # method         - The method the user is attempting to use. ex: :index, :create, :destroy, :custom_name
    def initialize(current_user, method, current_branch=nil)
      @current_user = current_user
      @current_branch = current_branch
      @method = method.to_sym
      @roles = fetch_roles
    end

    # if you handle your roles differently you'll need to override.
    # use: rails g canner:fetch_roles
    # It must return either an array of strings/symbols, or an array of Role objects that have a 'name' method.
    def fetch_roles
      @current_user.nil? ? [] : @current_user.roles
    end

    # implement in your policy class to auto scope in an action
    def canner_scope
      raise ArgumentError, 'NOT IMPLEMENTED'
      # ex:
      # case @method
      # when :index
      #   User.by_branch(@current_branch)
      # else
      #   User.none
      # end
    end

    # implement in your policy class.
    # return true when the user can access the action or resource and false when they can't
    def can?
      raise ArgumentError, 'NOT IMPLEMENTED'
      # ex:
      # case @method
      # when :index, :show
      #   has_role?(:admin)
      # else
      #   false
      # end
    end

    # accepts array of string, symbols or a mix:  [:admin, 'guest']
    # also accepts a list of params as in has_role?(:admin, :guest)
    def has_role?(*check_roles)
      begin
        @roles.any? do |r|
          user_role = r.respond_to?(:name) ? r.name : r.to_s
          Util.prepare(check_roles).include?(user_role.to_sym)
        end
      rescue StandardError => e
        raise ArgumentError.new "Canner: Problem fetching user roles. If current_user.roles isn't how you do it see wiki for overriding fetch_roles. #{e.message}"
      end
    end

    protected

    def is_method?(methods)
      prepare(methods).include?(@method)
    end
  end
end
