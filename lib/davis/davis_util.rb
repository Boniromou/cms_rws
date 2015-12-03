module Davis
  module Util
    def self.get_machine_config(machine_token)
      return nil unless machine_token
      a = machine_token.split('|')
      {
        :property_id=>a[0],
        :zone_id=>a[1],
        :zone_name=>a[2],
        :location_id=>a[3],
        :location_name=>a[4],
        :machine_id=>a[5],
        :machine_name=>a[6],
        :uuid=>a[7]
      }
    end
  end
end

#p Davis::Util.get_machine_config("20000|1|01|4|0102|2|abc1234|6e80a295eeff4554bf025098cca6eb37")
