module Snaptime
  module Versioned
    extend ActiveSupport::Concern

    include Scopes
    include Relations

    module ClassMethods
      def delete(*_args)
        fail Exceptions::DeleteMethodsAreNotAvailable
      end

      def delete_all(*_args)
        fail Exceptions::DeleteMethodsAreNotAvailable
      end

      def versioned?
        true
      end
    end

    def _run_create_callbacks(*args, &block)
      super do
        ArHooks.before_create(self)
        yield
        ArHooks.after_create(self)
      end
    end

    # To make sure our before_update always runs after all other before_update
    # methods, we override {_run_update_callbacks}. This prevents cases where an
    # after_update callback changes the record after it has already been
    # detected as no-changed. In this case, no shadow clone would be created.
    def _run_update_callbacks(*args, &block)
      super do
        ArHooks.before_update(self)
        yield
      end
    end

    def destroy
      ArHooks.destroy(self)
    end

    def delete
      fail Exceptions::DeleteMethodsAreNotAvailable
    end
  end
end
