module Snaptime
  module Harvester
    def self.harvest_for(record)
      # ---------------------------------------------------------------
      # Build individual selects for each combination of table,
      # key fields and values.
      # ---------------------------------------------------------------
      selects = []

      queries = snaptime_queries(record.class, [record.natural_id], nil)

      queries.each do |klass, keys_and_values|
        keys_and_values.each do |key, values|
          selects << select_for(klass, key, values)
        end
      end

      # ---------------------------------------------------------------
      # Build master select that unions all of the above queries
      # TODO: Probably add a separate option for coalesce to avoid
      #   doubling the code for max and min.
      # ---------------------------------------------------------------
      rel = Snaptime.model_class
      rel = rel.from(
        "#{union_selects(*selects)} inner_snaptimes"
      )

      # TODO: Move to DB-specific adapter
      rel = rel.select(Arel.sql("LISTAGG(record_lookups, ';') WITHIN GROUP(ORDER BY record_lookups)").as('record_lookups'))

      Snaptime.consolidation_fields.each do |field, options|
        if options[:aggregate_with].nil?
          rel = rel.select(field)
        elsif options[:aggregate_with] == :max
          rel = rel.select(Arel.sql(field.to_s).maximum.as(field.to_s))
        elsif options[:aggregate_with] == :max_coalesce_0
          rel = rel.select(
            Arel.sql(
              Arel::Nodes::NamedFunction.new('coalesce', [Arel.sql(field.to_s), Arel.sql(0.to_s)]).to_sql
            ).maximum.as(field.to_s)
          )
        elsif options[:aggregate_with] == :min
          rel = rel.select(Arel.sql(field.to_s).minimum.as(field.to_s))
        elsif options[:aggregate_with] == :min_coalesce_0
          rel = rel.select(
            Arel.sql(
              Arel::Nodes::NamedFunction.new('coalesce', [Arel.sql(field.to_s), Arel.sql(0.to_s)]).to_sql
            ).minimum.as(field.to_s)
          )
        elsif options[:aggregate_with] == :sum
          rel = rel.select(Arel.sql(field.to_s).sum.as(field.to_s))
        end
      end

      grouping_fields = Snaptime.consolidation_fields.select { |_k, v| v[:aggregate_with].nil? }.keys.collect(&:to_s)
      # rel = rel.order('inner_snaptimes.valid_from desc')
      rel = rel.order(Arel::Table.new(:inner_snaptimes)[:valid_from].desc)
      rel = rel.group(*grouping_fields)

      # ---------------------------------------------------------------
      # Wrap master select in another select so that outer orders,
      # wheres and counts work out-of-the-box.
      # ---------------------------------------------------------------
      all_keys = [:record_lookups] + Snaptime.consolidation_fields.keys

      all_fields = all_keys.collect do |key|
        Arel::Table.new(:snaptimes)[key]
      end

      outer_rel = Snaptime.model_class.select(all_fields).from("(#{rel.to_sql}) snaptimes")

      return outer_rel
    end

    def self.select_for(klass, key, values)
      table = klass.arel_table

      select = Arel::SelectManager.new(ActiveRecord::Base)
      select.from table

      concat = Arel::Nodes::NamedFunction.new('concat', [
        Arel.sql(klass.connection.quote("#{klass.name},")),
        table[klass.primary_key]
      ])
      select.project(
        concat.as('record_lookups')
      )

      Snaptime.consolidation_fields.each do |field_key, options|
        if klass.column_names.include?(field_key.to_s)
          select.project(table[field_key.to_s])
        else
          unless options[:default].is_a?(Arel::Nodes::SqlLiteral)
            fail 'Option :default must be an Arel::Nodes::SqlLiteral.'
          end
          select.project(options[:default].as(field_key.to_s))
        end
      end

      select.where(table[key].in(values))

      return select
    end

    private_class_method :select_for

    def self.snaptime_queries(klass, natural_ids, association, visited_natural_ids_by_assoc = {})
      queries = {}

      # ---------------------------------------------------------------
      # Abort if all natural IDs have already been processed for the
      # given association.
      # ---------------------------------------------------------------
      visited_natural_ids_by_assoc[association] ||= []
      return {} if (natural_ids - visited_natural_ids_by_assoc[association]).empty?
      visited_natural_ids_by_assoc[association] += natural_ids

      my_natural_ids = natural_ids

      if association.nil? || association.is_a?(ActiveRecord::Reflection::BelongsToReflection)
        # Either:
        #  I'm the root of the query, return all valid_from from my versions,
        #  which are identified by my natural_id.
        #
        # Or:
        #  I'm target of a belongs_to, I'm getting all natural_ids that my
        #  peer is pointing to with his foreign key. So I will return all
        #  valid_from that belong to these natural_ids.
        queries[klass] ||= {}
        queries[klass][:natural_id] ||= []
        queries[klass][:natural_id] += natural_ids
      elsif association.is_a?(ActiveRecord::Reflection::HasOneReflection) || association.is_a?(ActiveRecord::Reflection::HasManyReflection)
        # I'm target of a has_one / has_many, I'm getting my peer's
        # natural_id and have to return all valid_from of records that are
        # pointing to it.
        queries[klass] ||= {}
        queries[klass][association.foreign_key] ||= []
        queries[klass][association.foreign_key] += natural_ids

        # My own natural_ids for going further are the one's of the records that
        # are pointing to my peer.
        my_natural_ids = klass.unscoped.select(:natural_id).where(association.foreign_key => natural_ids).collect(&:natural_id)
      end

      klass.versioned_associations.each do |_name, nested_association|
        if nested_association.is_a?(ActiveRecord::Reflection::BelongsToReflection)
          # I have an association that I am pointing to. I'll have to supply
          # them with all the natural_ids I'm pointing to.

          table = Arel::Table.new(klass.table_name)

          natural_fks = klass
                        .unscoped
                        .select(nested_association.foreign_key)
                        .where(natural_id: my_natural_ids)
                        .where(table[nested_association.foreign_key].not_eq(nil))
                        .collect(&nested_association.foreign_key.to_sym)

          queries = merge_queries(
            queries,
            snaptime_queries(nested_association.klass, natural_fks, nested_association, visited_natural_ids_by_assoc)
          )
        elsif nested_association.is_a?(ActiveRecord::Reflection::HasOneReflection) || nested_association.is_a?(ActiveRecord::Reflection::HasManyReflection)
          # I have an association that points to me. I'll have to supply my
          # natural_ids of interest.
          queries = merge_queries(
            queries,
            snaptime_queries(nested_association.klass, my_natural_ids, nested_association, visited_natural_ids_by_assoc)
          )
        else
          fail "Unsupported relation type #{nested_association.class}."
        end
      end

      return queries
    end

    private_class_method :snaptime_queries

    def self.merge_queries(a, b)
      a.deep_merge b do |_key, val_a, val_b|
        (val_a + val_b).uniq
      end
    end

    private_class_method :merge_queries

    def self.union_selects(*selects)
      stmt = selects.collect(&:to_sql).collect { |sql| "(#{sql})" }.join("\nUNION\n")
      return "(#{stmt})"
    end

    private_class_method :union_selects
  end
end
