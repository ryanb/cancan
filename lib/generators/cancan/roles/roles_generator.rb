module Cancan
  module Generators
    class RolesGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      include Rails::Generators::Actions
      source_root File.expand_path('../templates', __FILE__)

      def self.next_migration_number(path)
        unless @prev_migration_nr
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        else
          @prev_migration_nr += 1
        end
        @prev_migration_nr.to_s
	    end

			def copy_migrations
				migration_template "roles.rb", "db/migrate/create_roles"
				migration_template "migration.rb", "db/migrate/create_#{singular_name}_roles"
			end
			
			def generate_role_model
				invoke "active_record:model", ["role"], :migration => false 
			 # invoke "active_record:model", ["#{singular_name}_role"], :migration => false
			 create_file Rails.root.join("app", "models", "#{singular_name}_role.rb"), "class UserRole < ActiveRecord::Base

end"		
			end  
			
#			def generate_user_role_model
#			  #template "user_role.rb", "app/models/user_role.rb"			
#				invoke "active_record:model", ["#{singular_name}_role"], :migration => false		
#			end	
						
			def insert_model_contents
				inject_into_class "app/models/#{singular_name}.rb", class_name do <<-CONTENT
					has_many :#{singular_name}_roles
					has_many :roles, :through => :#{singular_name}_roles
					# It checks the #{plural_name} role from the #{singular_name}_role table.
					 def role?(role)
						 self.roles ? roles.map{|role| role.name}.include?(role.to_s) : false
					 end
				CONTENT
				end
				inject_into_class "app/models/role.rb", Role do <<-CONTENT
					has_many :#{singular_name}_roles
		      has_many :#{plural_name}, :through => :#{singular_name}_roles
		    CONTENT
				end
				inject_into_class "app/models/#{singular_name}_role.rb", "#{class_name}Role".constantize do <<-CONTENT
					belongs_to :#{singular_name}
          belongs_to :role
				CONTENT
				end  
			end
			
			def rake_task_to_create_roles
				rakefile("create_roles.rake") do
					%Q{
						task :create_roles => :environment do
						   def ask message
								print message
								STDIN.gets.chomp
							 end
							#if yes?("Would you like to create roles?")
								role1 = ask("\nCreate a new first role:")
								first_role = Role.create(:name => role1)
								first_role.save!
								role2 = ask("\nCreate a new second role:")
								second_role = Role.create(:name => role2)
								second_role.save!
								role3 = ask("\nCreate a new third role:")
								third_role = Role.create(:name => role3)
								third_role.save!
							#end
						end
					}
				end
			end 
			
			def run_rake_task
			  rake("db:migrate")
				rake("create_roles")
			end	
    end
  end
end
