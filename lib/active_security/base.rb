module ActiveSecurity
  # ## Setting Up ActiveSecurity in Your Model
  #
  # To use ActiveSecurity in your ActiveRecord models, you must first either extend or
  # include the ActiveSecurity module (it makes no difference), then invoke the
  # {ActiveSecurity::Base#active_security active_security} method to configure your desired
  # options:
  #
  #     class Foo < ActiveRecord::Base
  #       include ActiveSecurity
  #       active_security :use => {finders: {default_finders: :restricted}, scoped: {scope: :bar_id}}
  #     end
  #
  # The most important option is `:use`, which you use to tell ActiveSecurity which
  # addons it should use. See the documentation for {ActiveSecurity::Base#active_security} for a list of all
  # available addons, or skim through the rest of the docs to get a high-level
  # overview.
  #
  # *A note about single table inheritance (STI): you must extend ActiveSecurity in*
  # *all classes that participate in STI, both your parent classes and their*
  # *children.*
  #
  # ### The Basic Setup: Simple Models
  #
  # By default the `:restricted` plugin is the only one configured, and the `restricted`
  # scope must be explicitly added to every query.
  # This is the simplest way to use ActiveSecurity.  But it is messy, and laborious.
  # It will ensure that finds are executed within a `where` scope:
  #
  #     class User < ActiveRecord::Base
  #       extend ActiveSecurity
  #     end
  #
  #     User.restricted.find(1)             # blows up, because no scope
  #     User.where(...).restricted.find(1)  # returns the user
  #
  # ### The Strict Setup: Magic Finders
  #
  # The problem with the above approach is that a naked find (`User.find(1)`)
  # still works, and is just as insecure as before. The `:finders` plugin fixes
  # this problem, so you don't need to add `restricted` everywhere.
  #
  #     class User < ActiveRecord::Base
  #       extend ActiveSecurity
  #       active_security use: {finders: {default_finders: :restricted}}
  #     end
  #
  #     User.find(1)                        # blows up, because no scope
  #     User.where(...).find(1)             # returns the user
  #     User.where(...).restricted.find(1)  # also returns the user
  module Base
    # Configure ActiveSecurity's behavior in a model.
    #
    #     class Post < ActiveRecord::Base
    #       extend ActiveSecurity
    #       active_security use: :finders
    #     end
    #
    # When given the optional block, this method will yield the class's instance
    # of {ActiveSecurity::Configuration} to the block before evaluating other
    # arguments, so configuration values set in the block may be overwritten by
    # the arguments. This order was chosen to allow passing the same proc to
    # multiple models, while being able to override the values it sets. Here is
    # a contrived example:
    #
    #     $active_security_config_proc = Proc.new do |config|
    #       config.use :finders
    #     end
    #
    #     class Foo < ActiveRecord::Base
    #       extend ActiveSecurity
    #       active_security &$active_security_config_proc
    #     end
    #
    #     class Bar < ActiveRecord::Base
    #       extend ActiveSecurity
    #       active_security &$active_security_config_proc
    #     end
    #
    # However, it's usually better to use {ActiveSecurity.defaults} for this:
    #
    #     ActiveSecurity.defaults do |config|
    #       config.use :finders, default_finders: :restricted
    #     end
    #
    #     class Foo < ActiveRecord::Base
    #       extend ActiveSecurity
    #     end
    #
    #     class Bar < ActiveRecord::Base
    #       extend ActiveSecurity
    #     end
    #
    # In general you should use the block syntax either because of your personal
    # aesthetic preference, or because you need to share some functionality
    # between multiple models that can't be well encapsulated by
    # {ActiveSecurity.defaults}.
    #
    # ### Order Method Calls in a Block vs Ordering Options
    #
    # When calling this method without a block, you may set the hash options in
    # any order, so long as they either have no dependencies, or are coupled with
    # their respective module.
    #
    # Here's an example that configures every plugin:
    #
    #     class Person < ActiveRecord::Base
    #       active_security use: {
    #         finders: {default_finders: :restricted},
    #         scoped: {scope: :name},
    #         privileged: {}
    #       }
    #     end
    #
    #     Person.find(1)                                 # blows up, because no scope
    #     Person.where(name: "Bart").find(1)             # returns the person
    #     Person.where(age: 29).find(1)                  # blows up, because name scope wasn't used
    #     Person.where(age: 29).privileged.find(1)       # returns the person, because privileged
    #     Person.where(name: "Bart").restricted.find(1)  # also returns the person, because name scope used
    #
    # However, when using block-style invocation, be sure to call
    # ActiveSecurity::Configuration's {ActiveSecurity::Configuration#use use} method
    # *prior* to the associated configuration options, because it will include
    # modules into your class, and these modules in turn may add required
    # configuration options to the `@active_security_configuration`'s class:
    #
    #     class Person < ActiveRecord::Base
    #       active_security do |config|
    #         # This will work
    #         config.use :scoped
    #         config.scope = "family_id"
    #       end
    #     end
    #
    #     class Person < ActiveRecord::Base
    #       active_security do |config|
    #         # This will fail
    #         config.scope = "family_id"
    #         config.use :scoped
    #       end
    #     end
    #
    # ### Including Your Own Modules
    #
    # Because :use can accept a name or a Module, {ActiveSecurity.defaults defaults}
    # can be a convenient place to set up behavior common to all classes using
    # ActiveSecurity. You can include any module, or more conveniently, define one
    # on-the-fly. For example, let's say you want to globally override the error
    # that is raised when no scope is used:
    #
    #     ActiveSecurity.defaults do |config|
    #       config.use :finders
    #       config.use Module.new {
    #         def self.setup(model_class)
    #           model_class.instance_eval do
    #             relation.class.send(:prepend, RaiseOverride)
    #             model_class.singleton_class.send(:prepend, RaiseOverride)
    #           end
    #
    #           association_relation_delegate_class = model_class.relation_delegate_class(::ActiveRecord::AssociationRelation)
    #           association_relation_delegate_class.send(:prepend, RaiseOverride)
    #         end
    #
    #         module RaiseOverride
    #           def raise_if_not_scoped
    #             puts "My errors are better than yours"
    #             raise StandardError, "Calm Down"
    #           end
    #         end
    #       }
    #     end
    #
    # @option options [Symbol, Module] :use The addon or name of an addon to use.
    #   By default, ActiveSecurity provides {ActiveSecurity::Finders :finders},
    #   {ActiveSecurity::Restricted :restricted}, {ActiveSecurity::Privileged :privileged},
    #   and {ActiveSecurity::Scoped :scoped}, or a hash where the keys are the symbolized
    #   module names just mentioned, and the values are hashes of options to set for each
    #   module.
    #
    # @option options [Symbol, Array[Symbol]] :scope Available when using `:scoped`.
    #   Sets the relation(s) or column(s) which will be considered a required scope.
    #   This option has no default value.
    #
    # @option options [Symbol] :default_finders Available when using `:finders`.
    #   Sets the type of scope enforcement to use. Must be one of :restricted or
    #   :privileged. Default value is :restricted.
    #
    # @option options [Module] :privileged_hooks Available when using `:privileged`.
    #   Sets the Module which defines the necessary hooks for the Privileged behavior.
    #   Default value is {ActiveSecurity::PrivilegedHooks}
    #
    # @option options [Module] :restricted_hooks Available when using `:restricted`.
    #   Sets the Module which defines the necessary hooks for the Restricted behavior.
    #   Default value is {ActiveSecurity::RestrictedHooks}
    #
    # @option options [Symbol, #call] :on_restricted_no_scope Available when using `:restricted`.
    #   Sets the Restricted behavior when the expected scope is not found. Must be one of
    #   the following [#call, :log, :log_and_raise, :raise].
    #   Default value is :log_and_raise.
    #
    # @option options [Symbol, #call] :on_restricted_unhandled_predicate Available when using `:restricted`.
    #   Sets the Restricted behavior when the scopes Arel Node has no defined handling. Must be one of
    #   the following [#call, :log, :log_and_raise, :raise].
    #   Default value is :log_and_raise.
    #
    # @yield Provides access to the model class's active_security_config, which
    #   allows an alternate configuration syntax, and conditional configuration
    #   logic.
    #
    # @yieldparam config The model class's {ActiveSecurity::Configuration active_security_config}.
    def active_security(options = {}, &block)
      yield active_security_config if block
      use_mods = options.delete(:use)
      if use_mods
        active_security_config.use(use_mods) do |config|
          config.send(:set, options)
        end
      else
        active_security_config.send(:set, options)
      end
    end

    # Returns the model class's {ActiveSecurity::Configuration active_security_config}.
    # @note In the case of Single Table Inheritance (STI), this method will
    #   duplicate the parent class's ActiveSecurity::Configuration and relation class
    #   on first access. If you're concerned about thread safety, then be sure
    #   to invoke {#active_security} in your class for each model.
    def active_security_config
      @active_security_config ||= base_class.active_security_config.dup.tap do |config|
        config.model_class = self
      end
    end
  end
end
