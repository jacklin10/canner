class BasePolicy

  def initialize(current_user, current_branch, method)
    @current_user = current_user
    @current_branch = current_branch
    @method = method.to_sym
    @roles = fetch_roles
  end

  # implement this in your policy class
  # expects an array or strings or symbols that represent the user roles
  def fetch_roles
    raise ArgumentError.new("YOU NEED TO IMPLEMENT")
    # ex. User.roles
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
    @roles.any?{|r| prepare(roles).include?(r.to_sym) }
  end

end
