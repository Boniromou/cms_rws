class AuditLogsController < ApplicationController
  layout 'cage'

  def search
    @action_lists = AuditLog::ACTION_MENU
  end
end
