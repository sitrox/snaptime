module Snaptime
  module Exceptions
    class DeleteMethodsAreNotAvailable < StandardError
      def initialize
        super('Versionized records only support the `destroy` methods.')
      end
    end

    class AssociationTargetNotVersioned < StandardError
      def initialize(target_class)
        super("Association target #{target_class.inspect} does not appear to be versioned.")
      end
    end
  end
end
