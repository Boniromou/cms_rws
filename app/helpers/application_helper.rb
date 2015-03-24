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
      else
        flash_type.to_s
    end
  end

  def button_class_for btn_type
    case btn_type
      when :complete
        { i_class: 'glyphicon glyphicon-ok', text: "Complete" }
      when :cancel
        { i_class: 'glyphicon glyphicon-remove', text: "Cancel" }
      when :re_schedule
        { i_class: 'glyphicon glyphicon-calendar', text: "Re-schedule" }
      when :extend
        { i_class: 'fa fa-plus', text: "Extend" }
      when :resume
        { i_class: 'fa fa-retweet', text: "Resume" }
      else
        raise NameError
    end
  end
=begin
  def dropbox_menu_for_select(tabs, selected=nil)
    content_tag :ul, :class => "dropdown-menu" do
      tabs.each do |title, url|
        content_tag :li, :class => (selected==title ? "active" : "") do
          link_to title, url
        end
      end
    end
  end
=end

  def parse_date(date_str, is_end_time=false)
    if is_end_time
      Time.strptime(date_str + " 23:59:59", "%Y-%m-%d %H:%M:%S")
    else
      Time.strptime(date_str, "%Y-%m-%d")
    end
  end

  def parse_datetime(datetime_str)
    Time.strptime(datetime_str, "%Y-%m-%d %H:%M:%S")
  end
end
