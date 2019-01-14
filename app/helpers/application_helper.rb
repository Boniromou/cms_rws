module ApplicationHelper
  def bootstrap_class_for flash_type
    case flash_type
      when :success
        "alert-success"
      when :error
        "alert-danger"
      when :alert
        "alert-warning"
      when :notice
        "alert-info"
      when :fail
        "alert-warning"
      else
        flash_type.to_s
    end
  end
 
  def approval_tree_li(target, actions, options={})
    li = nil
    actions.each do |action|
        li = content_tag(:li, id: "nav_#{target}") do
          path = case action
          when 'index' then eval("#{target.to_s.pluralize}_path")
          else eval("#{target.to_s.pluralize}_path") end
          link_to path do
            title = options[:title] || I18n.t("tree_view.#{target}")
            "<i class='fa fa-lg fa-fw fa #{options[:icon]}'></i><span class='menu-item-parent'> #{title}</span>".html_safe
          end
        end
    end
    li
  end
end
