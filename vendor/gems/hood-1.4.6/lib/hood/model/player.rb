module Hood
  class Player < Sequel::Model
    STATE_LOCKED = 'locked'
    STATE_UNLOCKED = 'unlocked'
    LOCK_EXPIRES = 300

    def credit_enable?
      Property.credit_enable?(self[:property_id])
    end

    def credit_expired?
      self[:credit_expired_at] && (self[:credit_expired_at] < Time.now) && self[:credit_balance] > 0
    end

    def balance_info
      info = {:balance => AmtUtil.cent2dollar(self[:balance])}
      if credit_enable?
        info[:credit_balance] = AmtUtil.cent2dollar(self[:credit_balance])
        if self[:credit_expired_at]
          info[:credit_expired_at] = TimeUtil.to_local_str(self[:credit_expired_at],Property.get_time_zone(self[:property_id]))
        else
          info[:credit_expired_at] = nil
        end
        info[:credit_is_expired] = credit_expired? ? true : false
      end
      info
    end

    class << self
      def query_balance(property_id,login_name)
        player = Player[:login_name=>login_name,:property_id=>property_id]
        raise InvalidLoginName unless player
        player.balance_info
      end

      def query_balances(property_id,login_names)
        players = Player.where(:login_name=>login_names,:property_id=>property_id).all
        res = players.map do |p|
          {:login_name=>p[:login_name]}.merge(p.balance_info)
        end
        {:players => res}
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
                                :created_at=>Time.now.utc,:updated_at=>Time.now.utc,
                               :credit_balance=>0,:seq=>0)
        end
      end

      def create_or_check_internal_account(property_id, login_name, currency, shareholder, player_id, player_currency_id)
        player = Player[:property_id => property_id, :login_name => login_name]
        if player
          raise VendorNotMatch unless player[:shareholder] == shareholder
          raise CurrencyNotMatch unless Currency[player[:currency_id]][:name] == currency
          raise AlreadyCreated
        else
          Currency.dataset.insert(  :id => player_currency_id,
                                    :name => currency,
                                    :created_at => Time.now.utc,
                                    :updated_at => Time.now.utc) if Currency[player_currency_id].nil?
          Player.dataset.insert(:id => player_id,
                                :login_name => login_name,
                                :currency_id => player_currency_id,
                                :balance => 0,
                                :shareholder => shareholder,
                                :property_id => property_id,
                                :lock_state => STATE_UNLOCKED,
                                :created_at => Time.now.utc,
                                :updated_at => Time.now.utc,
                               :credit_balance =>0,:seq=>0)
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
