require 'rubygems'
require 'sequel'
# load Sequel extension Inflector in order to make it compatible 
# with newer version of Sequel (version 3 or above)
require 'sequel/extensions/inflector' if Sequel::VERSION.split('.')[0].to_i >= 3
require 'lax-support/sequel_ext'

module LaxSupport
  class ModelError < StandardError
  end

  class StaleObjectError < ModelError
  end

  module LockVersionMethods
    def update(*args)
      rows = execute_dui(filter(:lock_version => args.first[:lock_version] - 1).update_sql(*args)){|c| c.affected_rows}
      raise StaleObjectError if rows == 0
      rows
    end
  end

  class Model 
    include LaxSupport::Callbacks

    attr_accessor :audit_columns

    define_callbacks :before_create, :after_create, 
                     :before_update, :after_update,
                     :before_save,   :after_save

    def initialize(ds={})
      @new = true
      @dataset = {}
      @audit_columns = [:created_at, :updated_at, :lock_version]
      self.class.columns.each { |k| @dataset[k] = nil }
      if ds.is_a?(Hash)
        @dataset.merge!(ds)
      else
        raise ArgumentError, 'Hash is expected as the initial parameter'
      end

      @new = @dataset[:id].nil? ? true : false
      @snapshot = @dataset.clone
    end 

    class << self
      attr_accessor :db, :table, :columns, :raise_on_save_failure

      def connect(*args, &block)
        db = Sequel.connect(*args, &block)
      end

      def db=(db)
        @db = db
        @table = @db.from(table_name)
        @columns = @table.columns 
        @raise_on_save_failure = true
        create_callbacks
      end

      def table_name
        name.split('::').last.underscore.pluralize
      end
  
      def find(*cond, &block)
        dataset = @table.filter(*cond, &block).all
        dataset.count == 0 ? [] : dataset.collect { |ds| new(ds) } 
      end

      def filter(*cond, &block)
        @table.filter(*cond, &block)
      end

      def create!(ds = nil)
        if ds.is_a?(Array)
          ds.collect { |attr| create!(attr) }
        else
          r = new(ds)
          r.save
          r
        end
      end

      def disconnect
        @db.disconnect
      end

      protected
   
      def create_callbacks
        if @columns.include?(:created_at)
          before_create_callbacks.delete(:timestamped_created_at) if before_create_callbacks
          before_create(:identifier => :timestamped_created_at) { |obj| obj[:created_at] = Time.now.utc if obj[:created_at].nil? }
        end

        if @columns.include?(:updated_at)
          before_save_callbacks.delete(:timestamped_created_at) if before_save_callbacks
          before_save(:identifier => :timestamped_updated_at) { |obj| obj[:updated_at] = Time.now.utc }
        end

        if @columns.include?(:lock_version)
          before_create_callbacks.delete(:lock_version) if before_create_callbacks
          before_update_callbacks.delete(:lock_version) if before_update_callbacks
          before_create(:identifier => :lock_version) { |obj| obj[:lock_version] = 0 if obj[:lock_version].nil? }
          before_update(:identifier => :lock_version) { |obj| obj[:lock_version] += 1 }

          table.extend(LockVersionMethods)
        end
      end
    end

    def audit_columns=(audit_cols)
      @audit_columns = audit_cols
    end

    def []=(name, value)
      if self.class.columns.include?(name.to_sym)
        @dataset[name.to_sym] = value
      else 
        raise ArgumentError, "#{name.to_sym} is not a valid attribute"
      end
    end

    def [](name)
      if self.class.columns.include?(name.to_sym)
        @dataset[name.to_sym]
      else
        raise ArgumentError, "#{name.to_sym} is not a valid attribute"
      end
    end

    def new?
      @new
    end

    def refresh_changeset!
      @changeset = @dataset.reject { |k, v| v == @snapshot[k] or audit_columns.include?(k) or k == :id}
    end

    def modified?
      refresh_changeset!
      not @changeset.empty?
    end

    def changeset
      @changeset
    end

    def save
      begin 
        if new?
          run_callbacks(:before_create)
          run_callbacks(:before_save)
          @dataset[:id] = self.class.table.insert(@dataset)
          run_callbacks(:after_save)
          run_callbacks(:after_create)
          @new = false
          @snapshot = @dataset.clone
        else
          # Save the changeset only
          save_changeset
        end
      rescue Exception => e
        if self.class.raise_on_save_failure 
          raise e
        else
          return false 
        end
      end

      return true
    end

    def save_changes
      begin
        # Save the changes only
        save_changeset
      rescue Exception => e
        if self.class.raise_on_save_failure
          raise e
        else
          return false
        end
      end
 
      return true
    end

    protected
    
    def save_changeset
      # Save the changeset only
      if modified?
        run_callbacks(:before_update)
        run_callbacks(:before_save)
        @dataset.inject(changeset) do |h, v| 
          h[v.first] = v.last if audit_columns.include?(v.first)
          h
        end
        rows = self.class.table.filter(:id => @dataset[:id]).update(changeset)
        run_callbacks(:after_save)
        run_callbacks(:after_update)
        @new = false
        @snapshot = @dataset.clone
        rows
      end
    end
  end
end
