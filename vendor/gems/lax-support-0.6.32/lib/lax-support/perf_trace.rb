module LaxSupport
  module PerfTrace
    # Default sampling rates
    DEFAULT_SAMPLE_RATE = 500 

    # Ensure class methods are mixed in correctly
    def self.included(base)
      base.extend ClassMethods
    end

    def ptrace!(method, sample_rate=DEFAULT_SAMPLE_RATE, name=nil)
      @traced_methods ||= {}
      method = method.to_sym
      name ||= method.to_s
      if @traced_methods.has_key?(method)
        @traced_methods[method][:sample_rate] = sample_rate
        @traced_methods[method][:name] = name
      else
        @traced_methods[method] = {}
        @traced_methods[method][:name]          = name
        @traced_methods[method][:sample_rate]   = sample_rate
        @traced_methods[method][:stats]         = Stats.new(name)
        @traced_methods[method][:inter_req]     = Stats.new("inter-request time for #{name} in Sec")
        @traced_methods[method][:current_value] = 0
        @traced_methods[method][:alias]         = self.class.create_alias(method, 'perftrace')
        self.class.register_ptrace(method, @traced_methods[method][:alias])
      end
    end

    def ptrace_methods!(methods)
      methods.each { |m| ptrace!(m['method'], m['sample_rate'], m['name']) }
    end

    def ptraced?(method)
      @traced_methods.has_key?(method.to_sym)
    end

    def unptrace!(method)
      method = method.to_sym
      if @traced_methods.has_key?(method)
        self.class.unregister_ptrace(method, @traced_methods[method][:alias])
        @traced_methods[method][:stats] = nil
        @traced_methods.delete(method)
      end
    end

    def unptrace_methods!(methods)
      methods.each { |m| unptrace!(m['method']) }
    end

    def unptrace_methods_not_in!(methods)
      method_names = []
      methods.each { |m| method_names.push(m['method'].to_sym) }
 
      traced_method_names = @traced_methods.keys
      
      traced_method_names.each { |m| unptrace!(m) unless method_names.include?(m)  }
    end

    module ClassMethods  
      def register_ptrace(method, renamed_method)
        class_eval %{
          alias_method #{renamed_method.inspect},
                       #{method.inspect}

          def #{method}(*args)
            start_t = Time.now
            result = #{renamed_method}(*args)
            time_elapsed = Time.now - start_t
  
            if rand(@traced_methods[#{method.inspect}][:sample_rate]) + 1 == @traced_methods[#{method.inspect}][:sample_rate] 
              @traced_methods[#{method.inspect}][:stats].sample(time_elapsed)
  
              @traced_methods[#{method.inspect}][:stats].dump()
              @traced_methods[#{method.inspect}][:inter_req].dump() 
              @traced_methods[#{method.inspect}][:current_value] = time_elapsed
            end
            @traced_methods[#{method.inspect}][:inter_req].tick
            result
          end
        } 
      end
   
      def unregister_ptrace(method, method_alias)
        class_eval %{
          remove_method #{method.inspect}
          alias_method #{method.inspect}, #{method_alias.inspect}
        }   
      end

      # This is a helper function for alias chaining.
      # Given a method name (as a string or symbol) and a prefix, create
      # a unique alias for the method, and return the name of the alias
      # as a symbol. Any punctuation characters in the original method name
      # will be converted to numbers so that operators can be aliased.
      def create_alias(original, prefix="alias")
        # Stick the prefix on the original name and convert punctuation
        aka = "#{prefix}_#{original}"
        aka.gsub!(/([\=\|\&\+\-\*\/\^\!\?\~\%\<\>\[\]])/) {
          num = $1[0]                       # Ruby 1.8 character -> ordinal
          num = num.ord if num.is_a? String # Ruby 1.9 character -> ordinal
          '_' + num.to_s
        }

        # Keep appending underscores until we get a name that is not in use
        aka += "_" while Module.method_defined? aka or Module.private_method_defined? aka

        aka = aka.to_sym            # Convert the alias name to a symbol
        #Module.alias_method aka, original  # Actually create the alias
        aka                         # Return the alias name
      end
    end
  end
end
