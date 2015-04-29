class FrontMoneyController < ApplicationController
  layout 'cage'
  def search
    
  end

  def do_search
    account_date = params[:accounting_date]
    shift_name = params[:shift_name]
    respond_to do |format|
      format.html { render partial: "front_money/search_result", formats: [:html] }
      format.js { render partial: "front_money/search_result", formats: [:js] }
    end
  end
end
