module CanCan
  # For use with Inherited Resources
  class InheritedResource < ControllerResource # :nodoc:
    def load_resource_instance
      if parent?
        @controller.send :association_chain
        @controller.instance_variable_get("@#{instance_name}")
      elsif new_actions.include? @params[:action].to_sym
        @controller.send :build_resource
      else
        @controller.send :resource
      end
    end

    def resource_base
      @controller.send :end_of_association_chain
    end
  end
end
