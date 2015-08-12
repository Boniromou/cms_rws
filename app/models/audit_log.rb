class AuditLog < ActiveRecord::Base
  attr_accessible :action, :action_by, :action_error, :action_status, :action_type, :audit_target, :description, :ip, :session_id, :created_at

  ACTION_MENU = {:all => { :all => "general.all" },
                 :player => { :all => "general.all",
                              :create => "player.create",
                              :deposit => "player.deposit",
                              :withdrawal => "player.withdrawal",
                              :edit => "player.edit",
                              :lock => "player.lock",
                              :unlock => "player.unlock"},
                 :player_transaction => { :all => "general.all",
                                          :print => "transaction_history.print" },
                 :shift => { :all => "general.all",
                             :roll_shift => "shift.roll" },
                 :location => { :all => "general.all",
                                :create => "button.create",
                                :enable => "button.enable",
                                :disable => "button.disable"},
                 :station => { :all => "general.all",
                               :create => "button.create",
                               :enable => "button.enable",
                               :disable => "button.disable",
                               :register => "button.register",
                               :unregister => "button.unregister"}
  }

  ACTION_TYPE_LIST = { 
    :player => {:create => "create", :deposit => "update", :withdrawal => "update", :edit => "update", :lock => "update", :unlock => "update"},
    :location => {:add => "create", :disable => "update", :enable => "update"},
    :station => {:create => "create", :disable => "update", :enable => "update", :register => "update", :unregister => "update"},
    :player_transaction => {:print => "read"},
    :shift => {:roll_shift => "create"}
  }

  scope :since, -> start_time { where("created_at > ?", start_time) if start_time.present? }
  scope :until, -> end_time { where("created_at < ?", end_time) if end_time.present? }
  scope :match_action_by, -> actioner { where("action_by LIKE ?", "%#{actioner}%") if actioner.present? }
  scope :by_target, -> target { where("audit_target = ?", target) if target.present? }
  scope :by_action, -> action { where("action = ?", action) if action.present? }
  scope :by_action_type, -> action_type { where("action_type = ?", action_type) if action_type.present? }
  scope :by_action_status, -> action_status { where("action_status = ?", action_status) if action_status.present? }

  def self.search_query(*args)
    audit_target = args[0]
    action = args[1]
    action_type = args[2]
    action_by= args[3]
    start_time = args[4]
    end_time = args[5]
    by_target(audit_target).by_action(action).by_action_type(action_type).match_action_by(action_by).since(start_time).until(end_time)
  end

  def self.player_log(action, action_by, ip, session_id, options={}, &block)
    compose_log(action, action_by, "player", ip, session_id, options, &block)
  end

  def self.location_log(action, action_by, ip, session_id, options={}, &block)
    compose_log(action, action_by, "location", ip, session_id, options, &block)
  end

  def self.station_log(action, action_by, ip, session_id, options={}, &block)
    compose_log(action, action_by, "station", ip, session_id, options, &block)
  end
  
  def self.fund_in_out_log(action, action_by, ip, session_id, options={}, &block)
    compose_log(action, action_by, "player", ip, session_id, options, &block)
  end

  def self.print_log(action, action_by, ip, session_id, options={}, &block)
    compose_log(action, action_by, "player_transaction", ip, session_id, options, &block)
  end

  def self.shift_log(action, action_by, ip, session_id, options={}, &block)
    compose_log(action, action_by, "shift", ip, session_id, options, &block)
  end

  class << self
    def instance
      @audit_log = AuditLog.new unless @audit_log
      @audit_log
    end
  end

  private
  def self.compose_log(action, action_by, audit_target, ip, session_id, options={}, &block)
    content = options.merge({:action => action, :action_by => action_by, :audit_target => audit_target, :ip => ip, :session_id => session_id})
    begin
      block.call if block
      logging(content)
    rescue Exception => e
      unless e.class == ArgumentError
        logging(content.merge({:action_error => e.message, :action_status => "fail"}))
      end
      raise e
    end
  end

  def self.logging(content={})
    action = content[:action]
    action_by = content[:action_by]
    action_error = content[:action_error]
    action_status = content[:action_status] || "success"
    audit_target = content[:audit_target]
    action_type = content[:action_type] || ACTION_TYPE_LIST[audit_target.to_sym][action.to_sym]
    description = content[:description]
    ip = content[:ip]
    session_id = content[:session_id]
    content_to_insert = {:action => action, :action_by => action_by, :action_error => action_error, :action_status => action_status, :action_type => action_type, :audit_target => audit_target, :description => description, :ip => ip, :session_id => session_id}
    self.create!(content_to_insert)
    Rails.logger.info "[AuditLogs] capture an action and created a log with content=#{content_to_insert.inspect}"
  end
end
