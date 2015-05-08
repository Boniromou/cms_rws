module ViewsHelper
  def close_balance
    icon = create_icon("fa fa-times")
    content_tag(:a, icon, :href => home_path, "data-remote".to_sym => true, :id => "balance", :class => "btn btn-primary")
  end

  def close_fund_request
    icon = create_icon("fa fa-times")
    content_tag(:a, icon, :href =>  balance_path + "?member_id=#{@player.member_id}", "data-remote".to_sym => true, :id => "cancel", :class => "btn btn-primary")
  end

  def create_icon(style)
    content_tag(:i,"", :class => style)
  end

  def bread_crub(icon_style,title,subtitle)
    text = ""
    if subtitle.class == String
      subtitle = [subtitle]
    end

    subtitle.each do |str|
      text += " > " + str
    end
    subtitle_content = content_tag(:span, text)
    icon = create_icon(icon_style)    
    bread_content = content_tag(:h2, icon + "  " + title + "  " + subtitle_content, :class => "page-title txt-color-blueDark")
    bread = content_tag(:div, bread_content, :id => "breadcrumbs", :class => "col-xs-12 col-sm-7 col-md-7 col-lg-12")
    content_tag(:div, bread, :class => "row")
  end
end
