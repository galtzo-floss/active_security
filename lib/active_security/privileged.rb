module ActiveSecurity
  module Privileged
    class << self
      # Sets up behavior and configuration options for privileged feature.
      def included(model_class)
        model_class.active_security_config.instance_eval do
          self.class.send(:include, Configuration)
          defaults[:privileged_hooks] ||= ActiveSecurity::PrivilegedHooks
        end
        model_class.class_eval do
          extend(PrivilegedScope)
        end
      end
    end

    # This module adds `:privileged_hooks` to
    # {ActiveSecurity::Configuration ActiveSecurity::Configuration}.
    module Configuration
      attr_writer :privileged_hooks

      def privileged_hooks
        @privileged_hooks ||= defaults[:privileged_hooks]
      end
    end

    module PrivilegedScope
      # Returns a scope that is allowed to not require the secure scope, but will
      # be logged.
      # @see ActiveSecurity::FinderMethods
      # @see ActiveSecurity::Privileged
      def privileged
        all.extending(
          active_security_config.finder_methods,
          active_security_config.privileged_hooks
        )
      end
    end
  end
end
