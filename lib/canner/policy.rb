module Canner
  class Policy
    # current_user - The user whose access you are checking
    # current_branch - The optional 3rd access checking item.
    #                  For example, is Joe a manager at the Pittsburgh branch?
    #                  He may be a manager in the burgh, but not in Monaca.
    # method         - The controller method you are checking access to.
    #                  ex: :index, :destroy, :custom_name
    def initialize(current_user, method, current_branch = nil)
      @current_user = current_user
      @current_branch = current_branch
      @method = method.to_sym
      @roles = fetch_roles
    end

    # Return all the roles for the current user.
    #
    # This must return either:
    # 1. Array of strings/symbols.  [:admin, :manager, :guest]
    # 2. Array of objects that have a name method. [Role.new(name: 'admin')]
    #
    # If your user.roles method returns something else then you'll need to
    # override this method.
    # To easily override use the generator:
    # rails g canner:fetch_roles
    # Override case is if your user has permission objects like:
    # { user_id: 1, name: 'admin', branch: 'Pittsburgh'}
    # See github docs for examples.
    def fetch_roles
      @current_user.nil? ? [] : @current_user.roles
    end

    # Implement in your policy class to auto scope in an action
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

    # Implement in your policy class.
    # Return true when access is permitted, false when it isn't.
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

    # Used to determine if the user has any of the given roles.
    #
    # Accepts array of string, symbols or a mix:  has_role?[:admin, 'guest']
    # also accepts a list of params as in has_role?(:admin, :guest)
    def has_role?(*check_roles)
      begin
        @roles.any? do |role|
          user_role = role.respond_to?(:name) ? role.name : role.to_s
          Util.prepare(check_roles).include?(user_role.to_sym)
        end
      rescue StandardError => e
        raise ArgumentError, 'Canner: Problem fetching user roles. ' \
                             "If current_user.roles isn't how you do it " \
                             "see wiki for overriding fetch_roles. #{e.message}"
      end
    end
  end
end
