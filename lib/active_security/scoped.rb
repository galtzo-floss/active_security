module ActiveSecurity
  # ## Required Scope
  #
  # The {ActiveSecurity::Scoped} module allows ActiveSecurity to enforce querying
  # within a scope.
  #
  # This allows, for example:
  #
  #     class Restaurant < ActiveRecord::Base
  #       extend ActiveSecurity
  #       belongs_to :city
  #       active_security use: :scoped, scope: :city
  #     end
  #
  #     class City < ActiveRecord::Base
  #       extend ActiveSecurity
  #       has_many :restaurants
  #     end
  #
  #     City.find_by(name: "seattle").restaurants.restricted.find(23)
  #     City.find_by(name: "chicago").restaurants.restricted.find(23)
  #
  # The value for the `:scope` option can be the name of a `belongs_to` relation, or
  # a column.
  #
  # Additionally, the `:scope` option can receive an array of scope values:
  #
  #     class Cuisine < ActiveRecord::Base
  #       extend ActiveSecurity
  #       has_many :restaurants
  #     end
  #
  #     class City < ActiveRecord::Base
  #       extend ActiveSecurity
  #       has_many :restaurants
  #     end
  #
  #     class Restaurant < ActiveRecord::Base
  #       extend ActiveSecurity
  #       belongs_to :city
  #       active_security use: :scoped, scope: [:city, :cuisine]
  #     end
  #
  # All supplied values will be used to determine scope.
  #
  # ### Finding Records
  #
  # It's best to query through the relation:
  #
  #     @city.restaurants.restricted.find(23)
  #
  # Alternatively, you could pass the scope value as a query parameter:
  #
  #     Restaurant.where(city_id: @city.id).restricted.find(23)
  module Scoped
    class << self
      # Sets up behavior and configuration options for scoped feature.
      def included(model_class)
        model_class.class_eval do
          active_security_config.class.send(:include, Configuration)
        end
      end
    end

    # This module adds the `:scope` configuration option to
    # {ActiveSecurity::Configuration ActiveSecurity::Configuration}.
    module Configuration
      # Gets the scope value.
      #
      # When setting this value, the argument should be a symbol referencing a
      # `belongs_to` relation, or a column.
      #
      # @return Symbol The scope value
      attr_accessor :scope

      # Gets the scope columns.
      #
      # Checks to see if the `:scope` option passed to
      # {ActiveSecurity::Base#active_security} refers to a relation, and if so, returns
      # the relation's foreign key. Otherwise it assumes the option value was
      # the name of column and returns it cast to a String.
      #
      # @return String The scope column
      def scope_columns
        [@scope].flatten.map { |s| (reflection_foreign_key(s) or s).to_s }
      end

      private

      def reflection_foreign_key(scope)
        reflection = model_class.reflections[scope] || model_class.reflections[scope.to_s]
        reflection.try(:foreign_key)
      end
    end
  end
end
