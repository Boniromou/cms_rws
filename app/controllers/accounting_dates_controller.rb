class AccountingDatesController < ApplicationController
  layout false

  skip_before_filter :check_session_expiration, :authenticate_user!,:pass_terminal_id, :only => :current

  def current
    respond_to do |format|
      format.html { render :text => current_accounting_date.accounting_date , :layout => false }
    end
  end
end
