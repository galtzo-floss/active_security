# frozen_string_literal: true

# External Libraries
require "version_gem"
require "active_record"
require "active_support"

# This library
require_relative "active_security/base"
require_relative "active_security/configuration"
require_relative "active_security/finder_methods"
require_relative "active_security/privileged_hooks"
require_relative "active_security/restricted_hooks"
require_relative "active_security/version"

module ActiveSecurity
  class RestrictedAccessError < RuntimeError; end

  class UnhandledArelPredicateError < RuntimeError; end

  class InvalidConfig < ArgumentError; end

  autoload :Finders, "active_security/finders"
  autoload :Privileged, "active_security/privileged"
  autoload :Restricted, "active_security/restricted"
  autoload :Scoped, "active_security/scoped"

  class << self
    # ActiveSecurity takes advantage of `extended` to do basic model setup, primarily
    # extending {ActiveSecurity::Base} to add {ActiveSecurity::Base#active_security
    # active_security} as a class method.
    #
    # In addition to adding {ActiveSecurity::Base#active_security active_security}, the class
    # instance variable +@active_security_config+ is added. This variable is an
    # instance of an anonymous subclass of {ActiveSecurity::Configuration}. This
    # allows subsequently loaded modules like {ActiveSecurity::Scoped} to add
    # functionality to the configuration class only for the current class,
    # rather than monkey patching {ActiveSecurity::Configuration} directly.
    # This isolates other models from large feature changes an addon to
    # ActiveSecurity could potentially introduce.
    #
    # The upshot of this is, you can have two Active Record models that both have
    # a @active_security_config, but each config object can have different methods
    # and behaviors depending on what modules have been loaded, without
    # conflicts.  Keep this in mind if you're hacking on ActiveSecurity.
    #
    # For examples of this, see the source for {Scoped.included}.
    def extended(model_class)
      return if model_class.respond_to?(:active_security)
      class << model_class
        alias_method :relation_without_active_security, :relation
      end
      model_class.class_eval do
        extend(Base)

        @active_security_config = Class.new(Configuration).new(self) # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
        ActiveSecurity.defaults.call(@active_security_config) # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
      end
    end

    # Allow developers to `include` ActiveSecurity or `extend` it.
    def included(model_class)
      model_class.extend(self)
    end

    # Set global defaults for all models using ActiveSecurity.
    #
    # The default defaults are to use the `:restricted` module and nothing else.
    #
    # @example
    #   ActiveSecurity.defaults do |config|
    #     config.base :name
    #     config.use :something_else
    #   end
    def defaults(&block)
      @defaults = block if block # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
      @defaults ||= ->(config) { config.use(:restricted) } # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
    end

    # If you need to reset the defaults to original defaults, just call without a block:
    #
    #   ActiveSecurity.reset_defaults
    #
    def reset_defaults
      @defaults = nil # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
    end
  end
end

ActiveSecurity::Version.class_eval do
  extend VersionGem::Basic
end
