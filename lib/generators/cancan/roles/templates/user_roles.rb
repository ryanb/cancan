class CreateUserRoles < ActiveRecord::Migration
	def up
	  create_table :user_roles, :force => true do |t|
		  t.integer  "user_id",    :null => false
		  t.integer  "role_id",    :null => false
		  t.datetime "created_at"
		  t.datetime "updated_at"
		end
	end	
	
	def down
	  drop_table :user_roles
	end
end
