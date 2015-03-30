module Sequel
  class StaleObjectError < StandardError; end

  module Plugins
    module LockVersioned
      def self.apply(model, options={})
        locking_column = (options[:locking_column] || :lock_version).to_sym

        if model.columns.include?(locking_column)
          model.class_eval "before_create { self.#{locking_column} = 0 if self.#{locking_column}.nil? }" 
          model.class_eval "before_update { self.#{locking_column} += 1 }"

          model.dataset.meta_def(:locking_column) { locking_column }
          model.dataset.extend(LockVersionMethods)
          model.def_dataset_method(LockVersionMethods.public_instance_methods.map{|e| e.to_s})
        end
      end
 
      module LockVersionMethods
        def update(*args)
          rows = execute_dui(filter(locking_column => args.first[locking_column] - 1).update_sql(*args)){|c| c.affected_rows}
          raise StaleObjectError if rows == 0
          rows 
        end
      end 
    end
  end
end
