module AuditLogsHelper
  def display_action_status(status_val)
    case status_val 
      when "success"
        "general.success"
      when "fail"
        "general.fail"
      else
        nil
    end
  end

  def display_target(target_name)
    case target_name
      when "location"
        "general.location"
      when "station"
        "general.station"
      when "player"
        "general.player"
      when "player_transaction"
        "general.player_transaction"
      when "shift"
        "general.shift"
      else
        nil
    end
  end

  def display_action(action_name)
    case action_name
      when "create"
        "player.create"
      when "deposit"
        "player.deposit"
      when "withdrawal"
        "player.withdrawal"
      when "edit"
        "player.edit"
      when "print"
        "transaction_history.print"
      when "roll_shift"
        "shift.roll"
      when "lock"
        "player.lock"
      when "unlock"
        "player.unlock"
      when "enable"
        "button.enable"
      when "disable"
        "button.disable"
      when "unregister"
        "button.unregister"
      when "register"
        "button.register"
      when "add"
        "button.add"
      else
        nil
    end
  end

  def gen_hidden_action_list(action_lists, dom_id="action_lists_to_load")
    content_tag :div, :id => dom_id, :style => "display: none;" do
      action_lists.each do |audit_target, actions|
        actions_dom = content_tag(:div, :id => audit_target) do
          concat(options_for_select(actions.map { |action, action_local_key| [t(action_local_key), action] }))
        end
        concat actions_dom
      end
    end
  end
end
