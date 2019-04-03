module Snaptime
  module BaseArMixin
    extend ActiveSupport::Concern

    module ClassMethods
      def versioned?
        false
      end
    end

    def natural_id_or_id
      self.class.versioned? ? natural_id : id
    end
  end
end
