module StationHelper
  STATUS_HELPER = { 
    :active => { :action_str => "enable", :opposite => "inactive"},
    :inactive => { :action_str => "disable", :opposite => "active"}
    }
end
