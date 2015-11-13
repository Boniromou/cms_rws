module Cronjob
  class UpdatePlayerHelper
    PATH = {:integration0 => 'http://mo-int-pis-vapp01.rnd.laxino.com:80',
            :staging0 => 'http://mo-stg-pis-vapp01.rnd.laxino.com:80',
            :mockup0 => 'http://mo-mock-pis-vapp01.rnd.laxino.com:80'
            }
    def initialize(env)
      @env = end
    end
    def patron_requester(property_id, secret_key, env)
      patron_url = PATH[@env.to_sym]
      Requester::Patron.new(property_id, secret_key, patron_url)
    end

    def run
      properties = Property.all
      properties.each do |property|
        property_id = property.id
        secret_key = property.secret_key
        players = Token.joins(:player).select("players.member_id").where("expired_at > ? AND property_id = ?", Time.now, property_id).group("player_id")
        member_ids = ""
        players.each do |player|
          member_ids += ',' + player.member_id
        end
        member_ids = member_ids[1..-1]
        player_info_array = patron_requester(property_id, secret_key).get_player_infos(member_ids)
        player_info_array.each do |player_info|
          Player.update_info(player_info)
        end
      end
    end
  end
end
