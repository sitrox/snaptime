# rubocop: disable Metrics/ParameterLists

module Snaptime
  module RelationsBuilder
    def self.build_versioned_relation(klass, macro, name, scope = nil, options = {}, &extension)
      if scope.is_a?(Hash)
        options = scope
        scope   = nil
      end

      options[:primary_key] ||= (klass.versioned? ? :natural_id : klass.primary_key)

      versioned_scope = proc do
        rel = spawn.unscope(where: %i(valid_from valid_to))
        rel = rel.merge(scope) unless scope.nil?
        rel._at_explicit_snaptime(Snaptime.snaptime)
      end

      klass.send(macro, name, versioned_scope, options, &extension)

      reflection = klass.reflect_on_association(name)

      unless reflection.klass.versioned?
        fail Exceptions::AssociationTargetNotVersioned, reflection.klass
      end

      klass.versioned_associations = klass.versioned_associations.merge(
        name => reflection
      )
    end
  end
end
