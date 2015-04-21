module Hood
  class Player < Sequel::Model
    STATE_LOCKED = 'locked'
    STATE_UNLOCKED = 'unlocked'
    LOCK_EXPIRES = 300

    class << self
      def query_balance(property_id,login_name)
        player = Player[:login_name=>login_name,:property_id=>property_id]
        raise InvalidLoginName unless player
        {:balance=>AmtUtil.cent2dollar(player[:balance])}
      end

      def query_balances(property_id,login_names)
        players = Player.db[:players].where(:login_name=>login_names,:property_id=>property_id)
          .select(:login_name,:balance).all.map {|p| {:login_name=>p[:login_name],:balance=>AmtUtil.cent2dollar(p[:balance])}}
        {:players=>players}
      end

      def query_vendor_total_balance(property_id,shareholder)
        total_balance = Player.where(:shareholder=>shareholder,:property_id=>property_id).sum(:balance)
        {:total_balance=>AmtUtil.cent2dollar(total_balance)}
      end

      def create_or_check_account(property_id,login_name,currency,shareholder)
        player = Player[:property_id=>property_id,:login_name=>login_name]
        if player
          raise VendorNotMatch unless player[:shareholder] == shareholder
          raise CurrencyNotMatch unless Currency[player[:currency_id]][:name] == currency
          raise AlreadyCreated
        else
          pi = AmsService.new.create_player(property_id,login_name,currency)
          raise CurrencyNotMatch unless pi[:currency] == currency
          Currency.dataset.insert(:id=>pi[:currency_id],:name=>currency,:created_at=>Time.now.utc,:updated_at=>Time.now.utc) if Currency[pi[:currency_id]].nil?
          Player.dataset.insert(:id=>pi[:id],:login_name=>pi[:login_name],:currency_id=>pi[:currency_id],:balance=>0,
                                :shareholder=>shareholder,:property_id=>property_id,:lock_state=>STATE_UNLOCKED,
                                :created_at=>Time.now.utc,:updated_at=>Time.now.utc)
        end
      end

      def lock(property_id,login_name)
        begin
          player = Player.acquire_lock(property_id,login_name)
          yield player
        ensure
          Player.release_lock(player[:id]) if defined?(player) && player
        end
      end

      def acquire_lock(property_id,login_name,try_count=3)
        player = Player[:property_id=>property_id,:login_name=>login_name]
        raise InvalidLoginName unless player
        try_count.times { |n|
          Player.db.transaction do
            player.lock!
            state = player[:lock_state]
            if state==STATE_UNLOCKED || player[:updated_at] + LOCK_EXPIRES < Time.now.utc
              player.modified!
              player.update(:lock_state=>STATE_LOCKED)
              return player
            end
          end
          sleep (0.1) unless n+1 >= try_count
        }
        raise InternalError.new('failed to acquire player lock')
      end

      def release_lock(player_id)
        Player.dataset.where(:id=>player_id).update(:lock_state=>STATE_UNLOCKED,:updated_at=>Time.now.utc)
      end

    end

  end
end
