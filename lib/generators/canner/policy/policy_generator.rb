module Canner
  module Generators
    class PolicyGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      check_class_collision suffix: "Policy"

      class_option :parent, type: :string, desc: "The parent class for the generated policy"

      def create_policy
        template 'policy.rb', File.join('app/policies', class_path, "#{file_name}_policy.rb")
      end

      hook_for :test_framework

      private

      def parent_class_name
        options.fetch("parent") do
          Canner::Policy
        end
      end

    end
  end
end
