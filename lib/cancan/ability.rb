module CanCan

  # This module is designed to be included into an Ability class. This will
  # provide the "can" methods for defining and checking abilities.
  #
  #   class Ability
  #     include CanCan::Ability
  #
  #     def initialize(user)
  #       if user.admin?
  #         can :access, :all
  #       else
  #         can :read, :all
  #       end
  #     end
  #   end
  #
  module Ability
    # Check if the user has permission to perform a given action on an object.
    #
    #   can? :destroy, @project
    #
    # You can also pass the class instead of an instance (if you don't have one handy).
    #
    #   can? :create, :projects
    #
    # Nested resources can be passed through a hash, this way conditions which are
    # dependent upon the association will work when using a class.
    #
    #   can? :create, @category => :projects
    #
    # Not only can you use the can? method in the controller and view (see ControllerAdditions),
    # but you can also call it directly on an ability instance.
    #
    #   ability.can? :destroy, @project
    #
    # This makes testing a user's abilities very easy.
    #
    #   def test "user can only destroy projects which he owns"
    #     user = User.new
    #     ability = Ability.new(user)
    #     assert ability.can?(:destroy, Project.new(:user => user))
    #     assert ability.cannot?(:destroy, Project.new)
    #   end
    #
    # Also see the RSpec Matchers to aid in testing.
    def can?(action, subject, attribute = nil)
      match = relevant_rules_for_match(action, subject, attribute).detect do |rule|
        rule.matches_conditions?(action, subject, attribute)
      end
      match ? match.base_behavior : false
    end

    # Convenience method which works the same as "can?" but returns the opposite value.
    #
    #   cannot? :destroy, @project
    #
    def cannot?(*args)
      !can?(*args)
    end

    # Defines which abilities are allowed using two arguments. The first one is the action
    # you're setting the permission for, the second one is the class of object you're setting it on.
    #
    #   can :update, :articles
    #
    # You can pass an array for either of these parameters to match any one.
    # Here the user has the ability to update or destroy both articles and comments.
    #
    #   can [:update, :destroy], [:articles, :comments]
    #
    # You can pass :all to match any object and :access to match any action. Here are some examples.
    #
    #   can :access, :all
    #   can :update, :all
    #   can :access, :projects
    #
    # You can pass a hash of conditions as the third argument. Here the user can only see active projects which he owns.
    #
    #   can :read, :projects, :active => true, :user_id => user.id
    #
    # See ActiveRecordAdditions#accessible_by for how to use this in database queries. These conditions
    # are also used for initial attributes when building a record in ControllerAdditions#load_resource.
    #
    # If the conditions hash does not give you enough control over defining abilities, you can use a block
    # along with any Ruby code you want.
    #
    #   can :update, :projects do |project|
    #     project.groups.include?(user.group)
    #   end
    #
    # If the block returns true then the user has that :update ability for that project, otherwise he
    # will be denied access. The downside to using a block is that it cannot be used to generate
    # conditions for database queries.
    #
    # IMPORTANT: Neither a hash of conditions or a block will be used when checking permission on a symbol.
    #
    #   can :update, :projects, :priority => 3
    #   can? :update, :projects # => true
    #
    # If you pass no arguments to +can+, the action, class, and object will be passed to the block and the
    # block will always be executed. This allows you to override the full behavior if the permissions are
    # defined in an external source such as the database.
    #
    #   can do |action, subject, object|
    #     # check the database and return true/false
    #   end
    #
    def can(*args, &block)
      rules << Rule.new(true, *args, &block)
    end

    # Defines an ability which cannot be done. Accepts the same arguments as "can".
    #
    #   can :read, :all
    #   cannot :read, Comment
    #
    # A block can be passed just like "can", however if the logic is complex it is recommended
    # to use the "can" method.
    #
    #   cannot :read, :projects do |product|
    #     product.invisible?
    #   end
    #
    def cannot(*args, &block)
      rules << Rule.new(false, *args, &block)
    end

    # Alias one or more actions into another one.
    #
    #   alias_action :update, :destroy, :to => :modify
    #   can :modify, :comments
    #
    # Then :modify permission will apply to both :update and :destroy requests.
    #
    #   can? :update, :comments # => true
    #   can? :destroy, :comments # => true
    #
    # This only works in one direction. Passing the aliased action into the "can?" call
    # will not work because aliases are meant to generate more generic actions.
    #
    #   alias_action :update, :destroy, :to => :modify
    #   can :update, :comments
    #   can? :modify, :comments # => false
    #
    # The following aliases are added by default for conveniently mapping common controller actions.
    #
    #   alias_action :index, :show, :to => :read
    #   alias_action :new, :to => :create
    #   alias_action :edit, :to => :update
    #
    # This way one can use params[:action] in the controller to determine the permission.
    def alias_action(*args)
      target = args.pop[:to]
      aliases[:actions][target] ||= []
      aliases[:actions][target] += args
    end

    # Alias one or more subjects into another one.
    #
    #   alias_subject :admins, :moderators, :to => :users
    #   can :update, :users
    #
    # Then :modify permission will apply to both :update and :destroy requests.
    #
    #   can? :update, :admins # => true
    #   can? :update, :moderators # => true
    #
    # This only works in one direction. Passing the aliased subject into the "can?" call
    # will not work because aliases are meant to generate more generic subjects.
    #
    #   alias_subject :admins, :moderators, :to => :users
    #   can :update, :admins
    #   can? :update, :users # => false
    #
    def alias_subject(*args)
      target = args.pop[:to]
      aliases[:subjects][target] ||= []
      aliases[:subjects][target] += args
    end

    # Returns a hash of action and subject aliases.
    def aliases
      @aliases ||= default_aliases
    end

    # Removes previously aliased actions or subjects including the defaults.
    def clear_aliases
      aliases[:actions] = {}
      aliases[:subjects] = {}
    end

    def model_adapter(model_class, action)
      adapter_class = ModelAdapters::AbstractAdapter.adapter_class(model_class)
      adapter_class.new(model_class, relevant_rules_for_query(action, model_class.to_s.underscore.pluralize.to_sym))
    end

    # See ControllerAdditions#authorize! for documentation.
    def authorize!(action, subject, *args)
      message = nil
      if args.last.kind_of?(Hash)
        message = args.pop[:message]
      end
      attribute = args.first
      if cannot?(action, subject, *args)
        message ||= unauthorized_message(action, subject)
        raise Unauthorized.new(message, action, subject)
      elsif sufficient_attribute_check?(action, subject, attribute) && sufficient_condition_check?(action, subject)
        fully_authorized!(action, subject)
      end
      subject
    end

    def unauthorized_message(action, subject)
      keys = unauthorized_message_keys(action, subject)
      variables = {:action => action.to_s}
      variables[:subject] = (subject.kind_of?(Symbol) ? subject.to_s : subject.class.to_s.underscore.humanize.downcase.pluralize)
      message = I18n.translate(nil, variables.merge(:scope => :unauthorized, :default => keys + [""]))
      message.blank? ? nil : message
    end

    def attributes_for(action, subject)
      attributes = {}
      relevant_rules(action, subject).map do |rule|
        attributes.merge!(rule.attributes_from_conditions) if rule.base_behavior
      end
      attributes
    end

    def has_block?(action, subject)
      relevant_rules(action, subject).any?(&:only_block?)
    end

    def has_raw_sql?(action, subject)
      relevant_rules(action, subject).any?(&:only_raw_sql?)
    end

    def has_instance_conditions?(action, subject)
      relevant_rules(action, subject).any?(&:instance_conditions?)
    end

    def has_attributes?(action, subject)
      relevant_rules(action, subject).any?(&:attributes?)
    end

    def fully_authorized?(action, subject)
      @fully_authorized ||= []
      @fully_authorized.include? [action.to_sym, subject.to_sym]
    end

    def fully_authorized!(action, subject)
      subject = subject.class.to_s.underscore.pluralize.to_sym unless subject.kind_of?(Symbol) || subject.kind_of?(String)
      @fully_authorized ||= []
      @fully_authorized << [action.to_sym, subject.to_sym]
    end

    def merge(ability)
      ability.send(:rules).each do |rule|
        rules << rule.dup
      end
      self
    end

    private

    def unauthorized_message_keys(action, subject)
      subject = (subject.kind_of?(Symbol) ? subject.to_s : subject.class.to_s.underscore.pluralize)
      [aliases_for(:subjects, subject.to_sym), :all].flatten.map do |try_subject|
        [aliases_for(:actions, action.to_sym), :access].flatten.map do |try_action|
          :"#{try_action}.#{try_subject}"
        end
      end.flatten
    end

    def sufficient_attribute_check?(action, subject, attribute)
      !(%w[create update].include?(action.to_s) && attribute.nil? && has_attributes?(action, subject))
    end

    def sufficient_condition_check?(action, subject)
      !((subject.kind_of?(Symbol) || subject.kind_of?(String)) && has_instance_conditions?(action, subject))
    end

    # Accepts an array of actions and returns an array of actions which match.
    # This should be called before "matches?" and other checking methods since they
    # rely on the actions to be expanded.
    def expand_aliases(type, items)
      items.map do |item|
        aliases[type][item] ? [item, *expand_aliases(type, aliases[type][item])] : item
      end.flatten
    end

    # Given an action, it will try to find all of the actions which are aliased to it.
    # This does the opposite kind of lookup as expand_aliases.
    def aliases_for(type, action)
      results = [action]
      aliases[type].each do |aliased_action, actions|
        results += aliases_for(type, aliased_action) if actions.include? action
      end
      results
    end

    def rules
      @rules ||= []
    end

    # Returns an array of Rule instances which match the action and subject
    # This does not take into consideration any hash conditions or block statements
    def relevant_rules(action, subject, attribute = nil)
      specificity = 0
      rules.reverse.each_with_object([]) do |rule, relevant_rules|
        rule.expanded_actions = expand_aliases(:actions, rule.actions)
        rule.expanded_subjects = expand_aliases(:subjects, rule.subjects)
        if rule.relevant?(action, subject, attribute) && rule.specificity >= specificity
          specificity = rule.specificity if rule.base_behavior
          relevant_rules << rule
        end
      end
    end

    def relevant_rules_for_match(action, subject, attribute)
      relevant_rules(action, subject, attribute).each do |rule|
        if rule.only_raw_sql?
          raise Error, "The can? and cannot? call cannot be used with a raw sql 'can' definition. The checking code cannot be determined for #{action.inspect} #{subject.inspect}"
        end
      end
    end

    def relevant_rules_for_query(action, subject)
      relevant_rules(action, subject, nil).each do |rule|
        if rule.only_block?
          raise Error, "The accessible_by call cannot be used with a block 'can' definition. The SQL cannot be determined for #{action.inspect} #{subject.inspect}"
        end
      end
    end

    def default_aliases
      {
        :subjects => {},
        :actions => {
          :read => [:index, :show],
          :create => [:new],
          :update => [:edit],
          :destroy => [:delete],
        }
      }
    end
  end
end
