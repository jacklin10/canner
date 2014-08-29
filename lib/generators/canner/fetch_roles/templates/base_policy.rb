class BasePolicy < Canner::Policy

  # results expected to be an array or strings or symbols that represent the user roles
  def fetch_roles
    @current_user.roles
  end

end
