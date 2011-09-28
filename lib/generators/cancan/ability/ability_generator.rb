module Cancan
  module Generators
    class AbilityGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def generate_ability
        copy_file "ability.rb", "app/models/ability.rb"
        if File.exist?(File.join(destination_root, "spec"))
          copy_file "ability_spec.rb", "spec/models/ability_spec.rb"
        else
          copy_file "ability_test.rb", "test/unit/ability_test.rb"
        end
      end
    end
  end
end
