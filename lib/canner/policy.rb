module Canner

  class Policy

    def initialize(current_user, method, current_branch=nil)
      @current_user = current_user
      @current_branch = current_branch
      @method = method.to_sym
      @roles = fetch_roles
    end

    # if you handle your roles differently you'll need to override.
    # use: rails g canner:fetch_roles
    # expects an array or strings or symbols that represent the user roles
    def fetch_roles
      @current_user.nil? ? [] : @current_user.roles
    end

    # implement in your policy class to auto scope in an action
    def canner_scope
      raise ArgumentError.new("NOT IMPLEMENTED")
      # ex:
      # case @method
      # when :index
      #   User.by_branch(@current_branch)
      # else
      #   User.none
      # end
    end

    # implment in your policy class.
    # return true when the user can access the action or resource and false when they can't
    def can?
      raise ArgumentError.new("NOT IMPLEMENTED")
      # ex:
      # case @method
      # when :index, :show
      #   has_role?(:admin)
      # else
      #   false
      # end
    end

    protected

    def is_method?(methods)
      prepare(methods).include?(@method)
    end

    def has_role?(roles)
      begin
        @roles.any?{|r| Util.prepare(roles).include?(r.name.to_sym) }
      rescue Exception => e
        raise ArgumentError.new "Canner: Problem fetching user roles. If current_user.roles isn't how you do it see wiki for overriding fetch_roles."
      end
    end

  end

end
