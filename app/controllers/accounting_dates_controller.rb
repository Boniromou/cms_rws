class AccountingDatesController < ApplicationController
  layout false

  skip_before_filter :check_session_expiration, :authenticate_user!, :only => :current

  def current
    @current_accounting_date = current_accounting_date.accounting_date
  end
end
