module Snaptime
  module ArHooks
    def self.before_create(record)
      if record.natural_id.nil?
        record.valid_from = Snaptime.current_now
        ActiveRecord::Base.uncached do
          record.natural_id = record.class.connection.next_sequence_value(record.class.sequence_name)
        end
      end
    end

    def self.after_create(record)
      Snaptime.record_cloned_in_current_tx(record)
    end

    def self.before_update(record)
      return unless Snaptime.record_cloning_enabled?

      if record.valid_to.nil? && record.changed? && !Snaptime.record_cloned_in_current_tx?(record)
        record.valid_from = Snaptime.current_now

        Snaptime::RecordCloner.clone_record!(
          record,
          override_attributes: { valid_to: record.valid_from - SMALLEST_TIME_UNIT },
          return_record: false
        )

        Snaptime.record_cloned_in_current_tx(record)
      end
    end

    def self.destroy(record)
      record.deleted = true
      record.version_is_minor = true if record.respond_to?(:version_is_minor=)
      record.save!
    end
  end
end
