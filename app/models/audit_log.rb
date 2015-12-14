class AuditLog < ActiveRecord::Base
  attr_accessible :audit_target, :action_type, :action, :action_status, :action_error, :session_id, :ip, :action_by, :action_at, :description
  validates_presence_of :audit_target, :action, :action_status, :action_by, :action_at#, :action_type
  validate :action_type, :inclusion => { :in => %w(create read update delete) }
  scope :since, -> start_time { where("action_at > ?", start_time) if start_time.present? }
  scope :until, -> end_time { where("action_at < ?", end_time) if end_time.present? }
  scope :match_action_by, -> actioner { where("action_by LIKE ?", "%#{actioner}%") if actioner.present? }
  scope :by_target, -> target { where("audit_target = ?", target) if target.present? }
  scope :by_action, -> action { where("action = ?", action) if action.present? }
  scope :by_action_type, -> action_type { where("action_type = ?", action_type) if action_type.present? }
  scope :by_action_status, -> action_status { where("action_status = ?", action_status) if action_status.present? }

  class << self
    def search_query(*args)
      args.extract_options!
      audit_target, action, action_type, action_by, start_time, end_time = args
      by_target(audit_target).by_action(action).by_action_type(action_type).match_action_by(action_by).since(start_time).until(end_time)
    end
  
    #
    # =>
    # def self.test_player_log(action, action_by, session_id, ip, options={}, &block)
    #   compose_log("test_player", action, action_by, session_id, ip, options, &block)
    # end
    #
    # ...
    #
    Rigi::AUDIT_CONFIG.each do |audit_target, _|
      define_method("#{audit_target}_log") do |*args, &block|
        send(:compose_log, audit_target, *args, &block)
      end
    end

    private
    def compose_log(*args, &block)
      options = args.extract_options!
      audit_target, action, action_by, session_id, ip = args
      content = options.merge({:audit_target => audit_target, :action => action, :action_by => action_by, :session_id => session_id, :ip => ip})
      begin
        block.call if block
      rescue Exception => e
        logging(content.merge({:action_error => e.message, :action_status => "fail"}))
        raise e
      end
      logging(content)
    end

    def logging(content={})
      audit_target = content[:audit_target]
      action = content[:action]
      action_by = content[:action_by]
      action_type = content[:action_type] || retrieve_action_type(audit_target, action)
      action_error = content[:action_error]
      action_status = content[:action_status] || "success"
      action_at = content[:action_at] || Time.now
      session_id = content[:session_id]
      ip = content[:ip]
      description = content[:description]
      content_to_insert = { :audit_target => audit_target, :action_type => action_type, :action_error => action_error, :action => action, :action_status => action_status, :action_by => action_by, :action_at => action_at, :session_id => session_id, :ip => ip, :description => description }
      self.create!(content_to_insert)
      Rails.logger.info "[AuditLogs] capture an action and created a log with content=#{content_to_insert.inspect}"
    end

    def retrieve_action_type(audit_target, action_name)
      Rigi::AUDIT_CONFIG[audit_target.to_sym][:action_name][action_name.to_sym][:action_type]
    end
  end
end
