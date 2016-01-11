module Hood
  class ParamUtil
    class << self
      def ensure_params_given(inbound,*arg)
        missing_params = []
        arg.each do |name|
          inbound[name] = nil if inbound[name] == ""
          missing_params.push(name.to_s) unless inbound[name]
        end
        if missing_params.size>0
          raise Hood::MissingRequiredParameters.new(missing_params)
        end
      end

      def ensure_amt_positive(inbound, *arg)
        arg.each do |name|
          raise Hood::InvalidAmount unless inbound[name] > 0
        end
      end

      def ensure_amt_nonnegative(inbound, *arg)
        arg.each do |name|
          raise Hood::InvalidAmount if inbound[name] < 0
        end
      end

      def amt_dollar_to_cent(inbound, *arg)
        arg.each do |name|
          inbound[name] = AmtUtil.dollar2cent(inbound[name]) if inbound.include?(name)
        end
      end
      
      def amt_cent_to_dollar(inbound, *arg)
        arg.each do |name|
          inbound[name] = AmtUtil.cent2dollar(inbound[name]) if inbound.include?(name)
        end
      end

      def to_i(inbound,*arg)
        arg.each do |name|
          inbound[name] = inbound[name].to_i if inbound.include?(name)
        end
      end

      def downcase(inbound,*arg)
        arg.each do |name|
          inbound[name].downcase! if inbound.include?(name)
        end
      end
    end
  end

  class AmtUtil
    class << self
      def cent2dollar(cent_amt)
        (cent_amt.to_f/100.0).to_f
      end

      def dollar2cent(dollar_amt)
        (dollar_amt.to_f*100).round
      end
    end
  end

  class TimeUtil
    class << self
      def check_time_range(from_time,to_time,time_zone)
        from_t = Time.parse(from_time + time_zone).utc
        to_t = Time.parse(to_time + time_zone).utc
        raise InvalidTimeRange.new('from_time is too early') if from_t < Time.now - 7 * 24 * 3600
        raise InvalidTimeRange.new('from_time should be earlier than to_time') if from_t >= to_t
        raise InvalidTimeRange.new('to_time is later than the current system time') if to_t > Time.now
        raise InvalidTimeRange.new('range is too large') if to_t - from_t > 3600
        [from_t,to_t]
      end

      def to_local_str(time,time_zone)
        time.getlocal(time_zone).strftime("%Y-%m-%d %H:%M:%S")
      end
    end
  end

end
