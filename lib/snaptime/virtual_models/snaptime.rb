module Snaptime
  module VirtualModels
    class Snaptime < ActiveRecord::Base
      def self.load_schema
        columns_hash
      end

      def self.columns
        [
          ActiveRecord::ConnectionAdapters::Column.new('valid_from', nil, ActiveRecord::Base.connection.send(:lookup_cast_type, :timestamp))
        ]
      end

      def self.columns_hash
        Hash[columns.map { |c| [c.name, c] }]
      end

      self.primary_key = :valid_from

      def record_lookups
        read_attribute(:record_lookups).split(';')
      end

      def records
        to_fetch = {}

        record_lookups.collect do |identifier|
          klass_name, id = identifier.split(',')

          to_fetch[klass_name] ||= Set.new
          to_fetch[klass_name] << id
        end

        records = []

        to_fetch.each do |klass_name, ids|
          records += klass_name.constantize.unscoped.find(ids.to_a)
        end

        return records
      end

      def model_names
        read_attribute(:model_names).split(',')
      end

      def models
        model_names.collect(&:constantize)
      end
    end
  end
end
