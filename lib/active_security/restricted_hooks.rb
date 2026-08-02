module ActiveSecurity
  module RestrictedHooks
    extend ActiveSupport::Concern

    VALID_CONFIG_VALUES = %i[log log_and_raise raise]

    def _active_security_not_scoped_handler
      return active_security_config.on_restricted_no_scope.call(active_security_config) if active_security_config.on_restricted_no_scope.respond_to?(:call)

      unless VALID_CONFIG_VALUES.include?(active_security_config.on_restricted_no_scope)
        raise InvalidConfig, "on_restricted_no_scope must either be set to a callable lambda/proc or one of [:log, :log_and_raise, :raise]"
      end

      if /log/.match?(active_security_config.on_restricted_no_scope)
        active_security_config.logger.error("#{_active_security_name_for} does not have secure scope: #{to_sql if respond_to?(:to_sql)}")
      end

      if /raise/.match?(active_security_config.on_restricted_no_scope)
        raise RestrictedAccessError.new("prevented query without a secure scope #{_active_security_name_for}")
      end
    end

    def _active_security_unhandled_predicate(predicate)
      return active_security_config.on_restricted_unhandled_predicate.call(active_security_config) if active_security_config.on_restricted_unhandled_predicate.respond_to?(:call)

      unless VALID_CONFIG_VALUES.include?(active_security_config.on_restricted_unhandled_predicate)
        raise InvalidConfig, "on_restricted_unhandled_predicate must either be set to a callable lambda/proc or one of [:log, :log_and_raise, :raise]"
      end

      if /log/.match?(active_security_config.on_restricted_unhandled_predicate)
        active_security_config.logger.error("#{_active_security_name_for} predicate type #{predicate.class.name} is unhandled; See: https://www.rubydoc.info/github/rails/rails/Arel/Nodes")
      end

      if /raise/.match?(active_security_config.on_restricted_unhandled_predicate)
        raise UnhandledArelPredicateError.new(
          "#{_active_security_name_for} predicate type #{predicate.class.name} is unhandled; See: https://www.rubydoc.info/github/rails/rails/Arel/Nodes"
        )
      end
    end
  end
end
