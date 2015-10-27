class ChangeHistory < ActiveRecord::Base
	scope :since, -> start_time { where("action_at >= ?", start_time) if start_time.present? }
  	scope :until, -> end_time { where("action_at <= ?", end_time) if end_time.present? }
  	scope :by_property_id, -> property_id { where("property_id = ?", property_id) if property_id.present? }

  	def search_query_by_time(start_time, end_time)
      by_transaction_id(transaction_id)
    end

	class << self
		def create(user, player, action)
			change_history = new
			change_history.action_by = user.name
			change_history.object = 'player'
			change_history.action = action
			change_history.change_detail = "Member ID: #{player.member_id}"
			change_history.property_id = user.property_id
			change_history.action_at = Time.now.utc
			change_history.save!
		end
	end
end