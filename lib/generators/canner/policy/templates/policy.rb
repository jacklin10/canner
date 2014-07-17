<% module_namespacing do -%>
class <%= class_name %>Policy < BasePolicy

  def canner_scope
    case @method
    when :index
      # Add any special scoping you might need here
      <%= class_name %>.all
    else
      <%= class_name %>.none
    end
  end

  def can?
    case @method
    when :index
      # has_role?(:admin)
    else
      false
    end
  end

end
<% end -%>
