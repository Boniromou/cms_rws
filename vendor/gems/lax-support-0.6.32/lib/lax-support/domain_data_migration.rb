require 'rubygems'
require 'sequel'
require 'set'

module LaxSupport

class DomainDataMigration
   def initialize(options = {})	
	config = YAML.load_file(File.join(Rails.root, 'config', options[:config_file] || 'domain_migration.yml'))[Rails.env]
	target = YAML.load_file(File.join(Rails.root, 'config', 'database.yml'))[Rails.env]
        @config = config

        @db_target = Sequel.connect(sprintf('%s://%s:%s@%s:%s/%s', target["adapter"],
                                                      target["username"],
                                                      target["password"],
                                                      target["host"],
                                                      target["port"],
                                                      target["database"]))

        unless @db_target.table_exists?(:domain_data)
                @db_target.create_table :domain_data, {:engine => 'InnoDB', :collate => 'utf8_bin'} do
                    primary_key :id
                    String :table
                    String :change, :size => 4096
                    String :action_type
                    Fixnum :version
                end
        end

        @change_sqls = []
    end

    def handle_migrate
	puts 'detecting data......'
	detected_data

	if @change_sqls.empty?
	   puts 'no updated data found, bye'
	else
   	   puts 'Sql review....'
	   @change_sqls.each {|statement|	puts "    #{statement[:target]}"}	

	   ans = ENV['always_confirm'] 
	   while (!['Y', 'n'].include?(ans))
  	       puts 'Are you sure?  [Y/n]'
   	       ans = STDIN.gets.chomp
	   end
	   if ans == 'Y'
	      migrate
	      puts 'domain data has been migrate'
	   else
	      puts 'Cancel!' 
	   end
	end
    end

    def handle_rollback
	current_version = @db_target[:domain_data].max(:version).to_i
	if current_version == 0
	   puts 'current version is 0, nth to rollback ,bye~'
	else
	   ans = nil
	   unless ENV['version'] == 'last_version'	   
  	       puts "input rollback version: (current version: #{current_version}, default rollback to #{current_version -1})"
  	       ans = STDIN.gets.chomp
	       while !(ans.match(/\A[0-9]+\Z/) && ans.to_i < current_version)
	          puts "#{ans} is not a valid version to rollback, please input again"
	          ans = STDIN.gets.chomp
	       end
	       ans = ans.to_i
	   end
   	   rollback(ans)
	   puts 'Rollback done!'
	end
    end

    def detected_data
	@config.each do |db_table|
          source = db_table['source_db']
          db_source = Sequel.connect(sprintf('%s://%s:%s@%s:%s/%s', source["adapter"] || 'mysql',
                                                      source["username"],
                                                      source["password"],
                                                      source["host"],
                                                      source["port"],
                                                      source["database"]))

          db_table['tables'].each do |table_hash|
                table = table_hash['source_table']
                target_table = table_hash['target_table'] || table

		unique_key = get_table_unique_key(table_hash)
                unique_key_array = db_source[table.to_sym].select(unique_key[:source_key]).all.to_set + 
			   @db_target[table.to_sym].select(unique_key[:target_key]).all.to_set

                unique_key_array.each do |unique_key_hash|
                    source_record = db_source[table.to_sym]\
                        .filter(get_unique_key_mapping(unique_key[:source_key], unique_key_hash)).all

		    unique_key_value = get_unique_key_mapping(unique_key[:target_key], unique_key_hash)
                    target_record = @db_target[target_table.to_sym]\
			.filter(unique_key_value).all

                    columns = {}
		    table_hash['columns'] ||= {}
                    table_hash['columns'].each_pair do |source_column, target_column|
                        target_column ||= source_column
                        columns[source_column] = target_column
                    end

                    if !source_record.empty? && !target_record.empty?
                        update_record(target_table, source_record, target_record, columns, unique_key_value)
                    elsif !source_record.empty? && target_record.empty?
                        insert_record(target_table, source_record, target_record, columns, unique_key_value)
                    elsif source_record.empty? && !target_record.empty?
                        raise Exception.new("Error: Try to delete undeletable record #{unique_key_value.inspect} in table #{target_table} !!!") unless table_hash['deletable'] == true
                        delete_record(target_table, source_record, target_record, unique_key_value)
                    else
                        next
                    end
                 end
             end
	end
  end

  def migrate
        version = @db_target[:domain_data].max(:version).to_i + 1
        @change_sqls.each do |statement|
           @db_target.transaction do
              @db_target.execute_dui(statement[:target])
              @db_target[:domain_data].insert(statement[:log].merge({:version => version}))
           end
        end
        @change_sqls = []
  end

  def rollback(rollback_to = nil)
        rollback_num = rollback_to || (@db_target[:domain_data].max(:version).to_i - 1)
        @db_target[:domain_data].filter(:version > rollback_num).order(:id.desc).all.each do |log_record|
           @db_target.transaction do
              change_hash = YAML.load(log_record[:change])
              send("rollback_#{log_record[:action_type]}", change_hash, log_record[:table])
              @db_target[:domain_data].filter(:id => log_record[:id]).delete
           end
        end
  end

protected
  def get_table_unique_key(table)
	if table['unique_key']
	   source_key = {}
	   target_key = {}
	   i = 1
	   table['unique_key'].each do |uni_source_key, uni_target_key|
		source_key[uni_source_key.to_sym] = "key#{i}".to_sym
		target_key[(uni_target_key.nil? ? uni_source_key.to_sym : uni_target_key.to_sym)] = "key#{i}".to_sym
		i += 1
	   end
	   return {:source_key => source_key, :target_key => target_key}
	else
	   return {:source_key => {:id => :key1}, :target_key => {:id => :key1}}
	end
  end

  def get_unique_key_mapping(key_hash, key_value)
	result = {}
	key_hash.each do |ori_key, std_key|
	   result[ori_key] = key_value[std_key]
	end
	return result
  end

  def rollback_insert(change, table)
        @db_target[table.to_sym].filter(change[:unique_key]).delete
  end

  def rollback_update(change, table)
        update_values = {}
        change.each_pair do |column, values|
           next if column == :unique_key
           update_values[column] = values[0]
        end
	update_values[:updated_at] ||= Time.now.utc
        @db_target[table.to_sym].filter(change[:unique_key]).update(update_values)
  end

  def rollback_delete(change, table)
        insert_values = {}
        change.each_pair do |column, values|
	   if column == :unique_key
	     values.each_pair do |uni_key, uni_value|
                insert_values[uni_key] = uni_value
             end
	   else
             insert_values[column] = values[0]
	   end
        end

	insert_values[:created_at] ||= Time.now.utc
        insert_values[:updated_at] ||= Time.now.utc
        @db_target[table.to_sym].insert(insert_values)
  end

  def update_record(target_table, source_record, target_record, columns, unique_key_value)
     update_values = {}
     change = {}
     columns.each_pair do |source_column, target_column|
         new_value = source_record[0][source_column.to_sym]
         old_value = target_record[0][target_column.to_sym]
         if new_value.to_s != old_value.to_s
            change[target_column.to_sym] = [old_value.to_s, new_value]
            update_values[target_column.to_sym] = new_value
         end
     end
     unless update_values.empty?
        update_values[:updated_at] ||= Time.now.utc
        sql_statement = {}
        sql_statement[:target] = @db_target[target_table.to_sym].filter(unique_key_value).update_sql(update_values)
        sql_statement[:log] = {:table => target_table, :action_type => 'update',
                               :change => change.merge({:unique_key => unique_key_value}).to_yaml}
        @change_sqls << sql_statement
     end
  end

  def insert_record(target_table, source_record, target_record, columns, unique_key_value)
     insert_values = {}
     change = {}
     columns.each_pair do |source_column, target_column|
        new_value = source_record[0][source_column.to_sym]
        change[target_column.to_sym] = [nil, new_value]
        insert_values[target_column.to_sym] = new_value
     end

     insert_values.merge!(unique_key_value)
     insert_values[:created_at] ||= Time.now.utc
     insert_values[:updated_at] ||= Time.now.utc

     sql_statement = {}
     sql_statement[:target] = @db_target[target_table.to_sym].insert_sql(insert_values)
     sql_statement[:log] = {:table => target_table, :action_type => 'insert',
                            :change => change.merge({:unique_key => unique_key_value}).to_yaml}
     @change_sqls << sql_statement
  end

  def delete_record(target_table, source_record, target_record, unique_key_value)
     change = {}
     target_record[0].each_pair do |target_column_sym, old_value|
        change[target_column_sym] = [old_value.to_s, nil]
     end

     sql_statement = {}
     sql_statement[:target] = @db_target[target_table.to_sym].filter(unique_key_value).delete_sql
     sql_statement[:log] = {:table => target_table, :action_type => 'delete', 
			    :change => change.merge({:unique_key => unique_key_value}).to_yaml}
     @change_sqls << sql_statement
  end

end

end
