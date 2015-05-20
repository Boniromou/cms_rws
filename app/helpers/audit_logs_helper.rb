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
      when "system_user"
        "user.system_user"
      when "maintenance"
        "maintenance.title"
      when "propagation"
        "propagation.title"
      when "test_player"
        "tree_view.test_player"
      else
        nil
    end
  end

  def display_action(action_name)
    case action_name
      when "lock"
        "user.lock"
      when "unlock"
        "user.unlock"
      when "edit_role"
        "user.edit_role"
      when "create"
        "maintenance.create"
      when "cancel"
        "maintenance.cancel"
      when "complete"
        "maintenance.complete"
      when "extend"
        "maintenance.extend"
      when "reschedule"
        "maintenance.reschedule"
      when "expire"
        "maintenance.expire"
      when "resume"
        "propagation.resume"
      when "add"
        "test_player.add"
      when "enable"
        "test_player.enable"
      when "disable"
        "test_player.disable"
      when "deprecate"
        "test_player.deprecate"
      when "recover"
        "test_player.recover"
      when "sync"
        "test_player.sync"
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
