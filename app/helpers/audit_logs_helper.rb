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

  def gen_audit_target_options
    selection = Rigi::AUDIT_CONFIG.map { |audit_target, v| [ t(v[:locale_key]), audit_target.to_s ] }
    selection.unshift([ t("general.all"), "all" ])
    options_for_select selection
  end

  def display_target(target_name)
    Rigi::AUDIT_CONFIG[target_name.to_sym][:locale_key]
  end

  def display_action(target_name, action_name)
    Rigi::AUDIT_CONFIG[target_name.to_sym][:action_name][action_name.to_sym][:locale_key]
  end

  def gen_hidden_action_list(dom_id="action_lists_to_load")
    action_lists = {}
    action_lists[:all] = { :all => "general.all" }
    Rigi::AUDIT_CONFIG.each do |audit_target, category|
      action_lists[audit_target] = {}
      action_lists[audit_target][:all] = "general.all"
      category[:action_name].map do |action, action_attribute|
        action_lists[audit_target][action] = action_attribute[:locale_key]
      end
    end

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
