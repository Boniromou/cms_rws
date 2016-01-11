module Hood
  class CreditAutoExpireTransaction < CreditExpireTransaction
    class << self
      def process(player,ib)
        return {:error_code=>'CreditNotYetExpired'} unless player.credit_expired?
        ib[:ref_trans_id] = SecureRandom.uuid
        ib[:credit_amt] = player[:credit_balance]
        t = CreditAutoExpireTransaction.new
        t.accept(player,ib)
      end
    end
  end
end

