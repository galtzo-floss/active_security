module ActiveSecurity
  # ## Performing Finds with ActiveSecurity
  #
  # ActiveSecurity offers enhanced finders which will search for your record while
  # ensuring that a particular scope is present. This makes it easy
  # to add ActiveSecurity to an existing application with minimal code modification.
  #
  # By default, these enhanced finders are available only on the `restricted` scope:
  #
  #     Restaurant.restricted.find(23)          #=> Will blow up, because no scope!
  #     Restaurant.find(23)                     #=> works
  #
  # ActiveSecurity overrides the default finder methods to perform
  # secure finds all the time. This requires modifying parts of Rails that do
  # not have a public API, which is hard to maintain and may cause
  # compatibility issues.
  #
  #     class Restaurant < ActiveRecord::Base
  #       extend ActiveSecurity
  #
  #       scope :active, -> {where(active: true)}
  #
  #       active_security use: :finders
  #     end
  #
  #     Restaurant.restricted.find(23)          #=> blows up, because no scope!
  #     Restaurant.find(23)                     #=> also blows up, because no scope!
  #     Restaurant.active.find(23)              #=> works, because scoped!
  #     Restaurant.active.restricted.find(23)   #=> also works, because scoped!
  #
  # ### Updating your application to use ActiveSecurity's finders
  #
  # Unless you've chosen to use the `:finders` addon, be sure to modify the finders
  # in your controllers to use the `restricted` scope. For example:
  #
  #     # before
  #     def set_restaurant
  #       @restaurant = Restaurant.find(params[:id])
  #     end
  #
  #     # after
  #     def set_restaurant
  #       @restaurant = Restaurant.restricted.find(params[:id])
  #     end
  #
  # #### Active Admin
  #
  # Unless you use the `:finders` addon, you should modify your admin controllers
  # for models that use ActiveSecurity with something similar to the following:
  #
  #     controller do
  #       def find_resource
  #         scoped_collection.restricted.find(params[:id])
  #       end
  #     end
  module Finders
    class << self
      # ActiveSecurity::Config.use will invoke this method when present, to allow
      # loading dependent modules prior to overriding them when necessary.
      def setup(model_class)
        model_class.class_eval do
          relation.class.send(:include, active_security_config.finder_methods)
          extend(active_security_config.finder_methods)
        end

        association_relation_delegate_class = model_class.relation_delegate_class(::ActiveRecord::AssociationRelation)
        association_relation_delegate_class.send(:include, model_class.active_security_config.finder_methods)
      end

      # Sets up behavior and configuration options for finders feature.
      def included(model_class)
        model_class.active_security_config.instance_eval do
          self.class.send(:include, Configuration)
          defaults[:default_finders] ||= :restricted
        end
      end

      # Sets up behavior and that depends on configuration
      def after_config(model_class)
        raise InvalidConfig, ":finders plugin must be used with default_finders set to one of :privileged, or :restricted" unless %i[restricted privileged].include?(model_class.active_security_config.default_finders)

        model_class.active_security_config.use(model_class.active_security_config.default_finders)
        model_class.class_eval do
          if active_security_config.default_finders == :privileged
            relation.class.send(:include, active_security_config.privileged_hooks)
            send(:extend, active_security_config.privileged_hooks)
          else
            relation.class.send(:include, active_security_config.restricted_hooks)
            send(:extend, active_security_config.restricted_hooks)
          end
        end
        association_relation_delegate_class = model_class.relation_delegate_class(::ActiveRecord::AssociationRelation)
        if model_class.active_security_config.default_finders == :privileged
          association_relation_delegate_class.send(:include, model_class.active_security_config.privileged_hooks)
        else
          model_class.active_security_config.default_finders
          association_relation_delegate_class.send(:include, model_class.active_security_config.restricted_hooks)
        end
      end
    end

    # This module adds the `:default_finders` configuration option to
    # {ActiveSecurity::Configuration ActiveSecurity::Configuration}.
    module Configuration
      # Gets the default_finders value.
      #
      # When setting this value, the argument should be a symbol, either
      # :restricted or :privileged.  Default is :restricted.
      #
      # @return Symbol The default_finders value
      attr_accessor :default_finders
    end
  end
end
