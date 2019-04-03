require 'snaptime/migration_helpers'
require 'snaptime/record_cloner'
require 'snaptime/harvester'
require 'snaptime/versioned/scopes'
require 'snaptime/exceptions'
require 'snaptime/relations_builder'
require 'snaptime/railtie'
require 'snaptime/ar_hooks'
require 'snaptime/base_ar_mixin'
require 'snaptime/relations'
require 'snaptime/virtual_models/snaptime'
require 'snaptime/versioned'

module Snptime
  SNAPTIME_REQUEST_STORE_KEY = :snaptime_snaptime
  CURRENT_NOW_REQUEST_STORE_KEY = :snaptime_current_now
  CLONED_RECORDS_STORE_KEY = :snaptime_cloned_records
  RECORD_CLONING_SWITCH_REQUEST_STORE_KEY = :snaptime_record_cloning
  SMALLEST_TIME_UNIT = 0.001

  @consolidation_fields = ActiveSupport::OrderedHash.new

  def self.register_consolidation_field(name, aggregate_with: nil, default: Arel.sql('null'))
    @consolidation_fields[name] = { aggregate_with: aggregate_with, default: default }
  end

  def self.consolidation_fields
    @consolidation_fields
  end

  @model_class = Snaptime::VirtualModels::Snaptime

  def self.model_class=(model_class)
    @model_class = model_class
  end

  def self.model_class
    @model_class
  end

  def self.with_snaptime(snaptime, &_block)
    previous_snaptime = RequestStore.store[SNAPTIME_REQUEST_STORE_KEY]

    RequestStore.store[SNAPTIME_REQUEST_STORE_KEY] = snaptime

    begin
      yield
    ensure
      RequestStore.store[SNAPTIME_REQUEST_STORE_KEY] = previous_snaptime
    end
  end

  def self.without_record_cloning(&_block)
    previous_setting = RequestStore.store[RECORD_CLONING_SWITCH_REQUEST_STORE_KEY]

    RequestStore.store[RECORD_CLONING_SWITCH_REQUEST_STORE_KEY] = false

    begin
      yield
    ensure
      RequestStore.store[RECORD_CLONING_SWITCH_REQUEST_STORE_KEY] = previous_setting
    end
  end

  def self.record_cloning_enabled?
    RequestStore.store[RECORD_CLONING_SWITCH_REQUEST_STORE_KEY] != false
  end

  def self.snaptime
    RequestStore.store[SNAPTIME_REQUEST_STORE_KEY]
  end

  def self.current_now
    RequestStore.store[CURRENT_NOW_REQUEST_STORE_KEY] ||= Time.now.utc
  end

  # Override the "current now" used for creating new versions. Only use this
  # method for testing purposes and make sure you use `reset_current_now` if
  # necessary. Use `with_fake_current_now` whenever possible.
  def self.fake_current_now(time)
    RequestStore.store[CURRENT_NOW_REQUEST_STORE_KEY] ||= time.utc
  end

  # Override the "current now" used for creating new versions. Only use this
  # method for testing purposes.
  def self.with_fake_current_now(time, &_block)
    fake_current_now time

    begin
      yield
    ensure
      reset_current_now
    end
  end

  def self.reset_current_now
    RequestStore.store[CURRENT_NOW_REQUEST_STORE_KEY] = nil
  end

  def self.record_cloned_in_current_tx(record)
    RequestStore.store[CLONED_RECORDS_STORE_KEY] ||= {}
    RequestStore.store[CLONED_RECORDS_STORE_KEY][record.class.table_name] ||= {}
    RequestStore.store[CLONED_RECORDS_STORE_KEY][record.class.table_name][record.send(record.class.primary_key)] = true
  end

  def self.record_cloned_in_current_tx?(record)
    RequestStore.store
                .try(:[], CLONED_RECORDS_STORE_KEY)
                .try(:[], record.class.table_name)
                .try(:[], record.send(record.class.primary_key)) || false
  end

  def self.reset_records_cloned_in_current_tx
    RequestStore.store[CLONED_RECORDS_STORE_KEY] = nil
  end

  def self.after_commit_or_rollback
    reset_current_now
    reset_records_cloned_in_current_tx
  end
end
