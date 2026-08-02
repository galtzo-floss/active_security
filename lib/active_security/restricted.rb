module ActiveSecurity
  module Restricted
    class << self
      # Sets up behavior and configuration options for restricted feature.
      def included(model_class)
        model_class.active_security_config.instance_eval do
          self.class.send(:include, Configuration)
          defaults[:restricted_hooks] ||= ActiveSecurity::RestrictedHooks
          defaults[:on_restricted_no_scope] ||= :log_and_raise
          defaults[:on_restricted_unhandled_predicate] ||= :log_and_raise
        end
        model_class.class_eval do
          extend(RestrictedScope)
        end
      end
    end

    # This module adds `:restricted_hooks`, `:on_restricted_no_scope`
    # and `:on_restricted_unhandled_predicate` configuration options to
    # {ActiveSecurity::Configuration ActiveSecurity::Configuration}.
    module Configuration
      attr_writer :restricted_hooks
      # Gets the on_restricted_no_scope value.
      #
      # When setting this value, the argument should either be a callable lambda/proc,
      # or one of :log, :log_and_raise, :raise.
      attr_writer :on_restricted_no_scope

      # Gets the on_restricted_unhandled_predicate value.
      #
      # When setting this value, the argument should either be a callable lambda/proc,
      # or one of :log, :log_and_raise, :raise.
      attr_writer :on_restricted_unhandled_predicate

      # @return Module The module to use for restricted_hooks
      def restricted_hooks
        @restricted_hooks ||= defaults[:restricted_hooks]
      end

      # @return Symbol The on_restricted_no_scope value
      def on_restricted_no_scope
        @on_restricted_no_scope ||= defaults[:on_restricted_no_scope]
      end

      # @return Symbol The on_restricted_unhandled_predicate value
      def on_restricted_unhandled_predicate
        @on_restricted_unhandled_predicate ||= defaults[:on_restricted_unhandled_predicate]
      end
    end

    module RestrictedScope
      # Returns a scope that includes the active_security restricted hooks.
      # @see ActiveSecurity::FinderMethods
      # @see ActiveSecurity::RestrictedHooks
      def restricted
        # Guess what? This causes Rails to invoke `extend` on the scope, which has
        # the well-known effect of blowing away Ruby's method cache. It would be
        # possible to make this more performant by subclassing the model's
        # relation class, extending that, and returning an instance of it in this
        # method. However, using Rails' public API improves compatibility
        # and maintainability. If you'd like to improve the performance, your
        # efforts would be best directed at improving it at the root cause
        # of the problem - in Rails - because it would benefit more people.
        all.extending(
          active_security_config.finder_methods,
          active_security_config.restricted_hooks
        )
      end
    end
  end
end
