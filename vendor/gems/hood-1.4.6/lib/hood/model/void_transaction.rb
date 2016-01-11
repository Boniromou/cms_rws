module Hood
  class VoidTransaction < CashierTransaction
    class << self
      def process(player,ib)
        trans_type = ib[:_event_name].to_s
        t = CashierTransaction[:ref_trans_id=>ib[:ref_trans_id],:property_id=>ib[:property_id],:trans_type=>trans_type]
        if t
          t.handle_duplicate_req(player,ib)
        else
          void_type = trans_type.sub(/void_/,'')
          ct= CashierTransaction[:ref_trans_id=>ib[:ref_trans_id],:property_id=>ib[:property_id],:trans_type=>void_type]
          if ct
            raise VoidTransactionNotMatch unless (ct[:amt]==ib[:amt] && ct[:player_id]==player[:id])
            t = self.new
            t.accept(player,ib)
          else
            raise VoidTransactionNotExist
          end
        end
      end
    end
  end
end

