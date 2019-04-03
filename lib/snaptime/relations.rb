# rubocop: disable Style/PredicateName

module Snaptime
  module Relations
    extend ActiveSupport::Concern

    included do
      class_attribute :versioned_associations
      self.versioned_associations = {}.freeze
    end

    module ClassMethods
      def has_one_versioned(name, scope = nil, options = {})
        RelationsBuilder.build_versioned_relation(self, :has_one, name, scope, options)
      end

      def has_many_versioned(name, scope = nil, options = {}, &extension)
        RelationsBuilder.build_versioned_relation(self, :has_many, name, scope, options, &extension)
      end

      def belongs_to_versioned(name, scope = nil, options = {})
        RelationsBuilder.build_versioned_relation(self, :belongs_to, name, scope, options)
      end
    end
  end
end
