class AccountingDatesController < ApplicationController
  layout false

  skip_before_filter :authenticate_user!, :only => :current

  def current
    @current_accounting_date = current_accounting_date.accounting_date
  end
end
