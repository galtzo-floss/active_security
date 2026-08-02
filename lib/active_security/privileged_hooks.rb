module ActiveSecurity
  module PrivilegedHooks
    extend ActiveSupport::Concern

    def _active_security_not_scoped_handler
      active_security_config.logger.warn("[Privileged] #{_active_security_name_for} does not have secure scope: #{to_sql if respond_to?(:to_sql)}")
    end

    def _active_security_unhandled_predicate(predicate)
      active_security_config.logger.error("[Privileged] #{_active_security_name_for} predicate type #{predicate.class.name} is unhandled; See: https://www.rubydoc.info/github/rails/rails/Arel/Nodes")
    end
  end
end
