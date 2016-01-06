module Cronjob
  class UpdatePlayerHelper
    def initialize(env, request_config_file)
      @env = env
      @request_config_file = request_config_file
    end

    def patron_requester(property_id)
      requester_factory = Requester::RequesterFactory.new(@request_config_file, @env, property_id, Property.get_property_keys[property_id])
      requester_factory.get_patron_requester
    end

    def run
      properties = Property.all
      properties.each do |property|
        property_id = property.id
        players = Token.joins(:player).select("players.member_id").where("expired_at > ? AND property_id = ?", Time.now, property_id).group("player_id")
        member_ids = ""
        players.each do |player|
          member_ids += ',' + player.member_id
        end
        member_ids = member_ids[1..-1]
        if member_ids.nil?
          puts 'no member need to update'
        end
        response = patron_requester(property_id).get_player_infos(member_ids)
        player_info_array = response.players
        player_info_array.each do |player_info|
          Player.update_info(player_info)
        end
      end
    end
  end
end
