module ViewsHelper
  def close_balance
    icon = content_tag(:i,"", :class => "fa fa-times")
    content_tag(:a, icon, :href => home_path, "data-remote".to_sym => true, :id => "balance", :class => "btn btn-primary")
  end

  def close_fund_request
    icon = content_tag(:i,"", :class => "fa fa-times")
    content_tag(:a, icon, :href =>  balance_path + "?member_id=#{@player.member_id}", "data-remote".to_sym => true, :id => "cancel", :class => "btn btn-primary")
  end
end
