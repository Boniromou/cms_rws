class Approval::ApplicationController < ::ApplicationController

  def approval_file
    YAML.load_file("#{Rails.root}/config/approval.yml").recursive_symbolize_keys
  rescue StandardError
    {}
  end

  def approval_titles(target, approval_action)
    approval_file[target.to_sym][approval_action.to_sym] if approval_file[target.to_sym]
  end
end
