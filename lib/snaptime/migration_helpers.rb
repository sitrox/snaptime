module Snaptime
  module MigrationHelpers
    def self.load
      ActiveRecord::ConnectionAdapters::Table.class_eval do
        include SchemaStatements::Table
      end

      ActiveRecord::ConnectionAdapters::AbstractAdapter.module_eval do
        include SchemaStatements::TopLevel
      end
    end

    module SchemaStatements
      module Table
        def versionize
          column :natural_id, :integer
          column :valid_from, :timestamp, precision: 3
          column :valid_to, :timestamp, precision: 3
          column :deleted, :boolean, null: false, default: 0

          index :natural_id
          index :valid_from
          index :valid_to

          index %i(natural_id valid_to), unique: true

          @base.execute %(
            ALTER TABLE "#{name.to_s.upcase}"
            ADD CONSTRAINT "#{name.to_s.upcase}_VCVD" CHECK (
              VALID_TO IS NULL OR VALID_FROM <= VALID_TO
            )
          )
        end

        def unversionize
          remove :natural_id
          remove :valid_from
          remove :valid_to
          remove :deleted
        end
      end

      module TopLevel
        def versionize_table(table_name)
          change_table table_name, &:versionize
        end

        def unversionize_table(table_name)
          change_table table_name, &:unversionize
        end
      end
    end
  end
end
