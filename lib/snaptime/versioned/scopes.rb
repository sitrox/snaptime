module Snaptime
  module Versioned
    module Scopes
      extend ActiveSupport::Concern

      included do
        default_scope do
          current_version
        end
      end

      module ClassMethods
        def current_version
          snaptime = Snaptime.snaptime
          _at_explicit_snaptime(snaptime)
        end

        def _at_explicit_snaptime(snaptime = nil)
          if snaptime.nil?
            where(valid_to: nil, deleted: false)
          else
            where(
              arel_table[:valid_from].lteq(snaptime).and(
                arel_table[:valid_to].eq(nil).or(
                  arel_table[:valid_to].gteq(snaptime)
                )
              ).and(
                arel_table[:deleted].eq(false)
              )
            )
          end
        end

        def at_snaptime
          _at_explicit_snaptime Snaptime.snaptime
        end
      end

      def snaptimes
        Harvester.harvest_for(self)
      end

      def with_snaptime(snaptime = nil)
        Snaptime.with_snaptime(snaptime) do
          yield at_snaptime
        end
      end

      def at_snaptime
        _at_explicit_snaptime Snaptime.snaptime
      end

      def all_versions
        self.class.unscoped.where('natural_id = ?', natural_id)
      end

      private

      def _at_explicit_snaptime(snaptime = nil)
        all_versions._at_explicit_snaptime(snaptime).first
      end
    end
  end
end
