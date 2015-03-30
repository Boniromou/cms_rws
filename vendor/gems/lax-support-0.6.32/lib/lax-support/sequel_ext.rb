class String
  # Converts a string into a Time or DateTime object, depending on the
  # value of Sequel.datetime_class
  def to_sequel_time
    begin
      if Sequel.datetime_class == DateTime
        DateTime.parse(self, Sequel.convert_two_digit_years)
      elsif defined?(Rails)
        Sequel.datetime_class.zone.parse(self)
      else
        # Assume datetime in database is always in UTC
        Sequel.datetime_class.parse(self + " UTC")
      end
    rescue => e
      raise Sequel::Error::InvalidValue, "Invalid #{Sequel.datetime_class} value '#{self}' (#{e.message})"
    end
  end
end
