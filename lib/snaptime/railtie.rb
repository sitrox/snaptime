module Snaptime
  class Railtie < Rails::Railtie
    railtie_name :snaptime

    initializer :snaptime do
      ActiveSupport.on_load :active_record do
        Snaptime::MigrationHelpers.load
      end

      ActiveRecord::Base.send :include, Snaptime::BaseArMixin

      ActiveRecord::Base.send :after_commit do
        Snaptime.after_commit_or_rollback
      end

      ActiveRecord::Base.send :after_rollback do
        Snaptime.after_commit_or_rollback
      end

      Snaptime.register_consolidation_field(:valid_from)
    end
  end
end
