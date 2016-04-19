module Cronjob
  class UpdatePlayerHelper
    def initialize(env, request_config_file)
      @env = env
      @request_config_file = request_config_file
    end

    def patron_requester(licensee_id)
      requester_factory = Requester::RequesterFactory.new(@request_config_file, @env, nil, licensee_id, nil)
      requester_factory.get_patron_requester
    end

    def run
      licensees = Licensee.all
      licensees.each do |licensee|
        licensee_id = licensee.id
        players = Token.joins(:player).select("players.member_id").where("expired_at > ? AND licensee_id = ?", Time.now.utc.to_formatted_s(:db), licensee_id).group("player_id")
        if players.length == 0
          puts 'no member need to update'
          return
        end
        member_ids = ""
        players.each do |player|
          member_ids += ',' + player.member_id
        end
        member_ids = member_ids[1..-1]
        response = patron_requester(licensee_id).get_player_infos(member_ids)
        player_info_array = response.players
        player_info_array.each do |player_info|
          Player.update_info(player_info)
        end
      end
    end
  end
end
