module Canner
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

      def copy_application_policy
        template 'base_policy.rb', 'app/policies/base_policy.rb'
      end
    end
  end
end
