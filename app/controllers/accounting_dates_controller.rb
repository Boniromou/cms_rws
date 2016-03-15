class AccountingDatesController < ApplicationController
  layout false

  skip_before_filter :check_session_expiration, :authenticate_user!,:pass_terminal_id, :only => :current

  def current
    result = default_accounting_date_widget_message
    result = current_accounting_date.accounting_date if current_casino_id
    respond_to do |format|
      format.html { render :text => result , :layout => false }
    end
  end
end
