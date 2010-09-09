module CanCan
  # For use with Inherited Resources
  class InheritedResource < ControllerResource # :nodoc:
    def load_resource_instance
      if parent?
        @controller.parent
      elsif new_actions.include? @params[:action].to_sym
        @controller.build_resource
      else
        @controller.resource
      end
    end

    def resource_base
      @controller.end_of_association_chain
    end
  end
end
