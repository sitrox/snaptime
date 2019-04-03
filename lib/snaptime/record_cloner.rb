module Snaptime
  class RecordCloner
    def self.clone_record!(record, override_attributes: {}, return_record: true)
      override_attribute_keys = override_attributes.keys

      table = record.class.arel_table

      cloned_column_names = record.class.column_names - [record.class.primary_key] - override_attribute_keys.collect(&:to_s)

      # ---------------------------------------------------------------
      # Prepare select statement
      # ---------------------------------------------------------------
      select = Arel::SelectManager.new(record.class)
      select.from table

      # Add primary key
      clone_id = next_id_for(record)
      select.project clone_id

      # Project custom column values
      override_attribute_keys.each do |key|
        select.project record.class.connection.quote(override_attributes[key])
      end

      # Project remaining (cloned) column values
      cloned_column_names.each do |col|
        select.project table[col.to_sym]
      end

      # Where statement for selecting the original record
      select.where(table[record.class.primary_key.to_sym].eq(record.send(record.class.primary_key)))

      # ---------------------------------------------------------------
      # Prepare insert statement
      # ---------------------------------------------------------------
      insert = Arel::InsertManager.new
      insert.into table
      insert.select select

      # Add primary key column name
      insert.columns << table[record.class.primary_key.to_sym]

      # Add override column names
      override_attribute_keys.each do |attr|
        insert.columns << table[attr.to_sym]
      end

      # Add remaining (cloned) column names
      cloned_column_names.each do |c|
        insert.columns << table[c.to_sym]
      end

      # ---------------------------------------------------------------
      # Execute statement
      # ---------------------------------------------------------------
      record.class.connection.execute(insert.to_sql)

      if return_record
        return record.class.find(clone_id)
      else
        return nil
      end
    end

    def self.next_id_for(record)
      # See https://github.com/rsim/oracle-enhanced/issues/1733
      ActiveRecord::Base.uncached do
        record.class.connection.next_sequence_value(record.class.sequence_name)
      end
    end
  end
end
