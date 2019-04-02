class TransactionApprovalsController < ApplicationController

  def index
    redirect_to approval.index_path(target: 'player_transaction', search_by: search_by, approval_action: 'exception_transaction', remote: true)
  end
  
  def merge_index
    redirect_to approval.index_path(target: 'player', search_by: search_merge_by, approval_action: 'merge_player', remote: true) 
  end
  
  def list_log
    redirect_to approval.logs_list_path(target: 'player_transcation', search_by: search_by, approval_action: 'exception_transaction', remote: true)
  end

  private

  def search_by
    { casino_id: current_user.casino_ids 
    }
  end

  def search_merge_by
    { licensee_id: current_licensee_id
    }
  end

  def all?
    current_user.has_admin_property?
  end
end
