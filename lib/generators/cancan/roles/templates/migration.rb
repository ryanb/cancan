class Create<%= singular_name.camelize %>Roles < ActiveRecord::Migration
	def up
	  create_table :<%= singular_name %>_roles, :force => true do |t|
		  t.integer  :<%= singular_name%>_id,    :null => false
		  t.integer  "role_id",    :null => false
		  t.datetime "created_at"
		  t.datetime "updated_at"
		end
	end	
	
	def down
	  drop_table :<%= name %>_roles
	end
end
