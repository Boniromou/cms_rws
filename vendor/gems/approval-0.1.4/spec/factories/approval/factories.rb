FactoryGirl.define do
  factory(:request, :class => Approval::Request) do
    target "property_game_title_config"
    sequence(:target_id)
    action "set_rtp"
    sequence(:data) { |n| {"remark"=>{"num"=>"num_#{n}"}, "change_to"=>{"config"=>"#{n}"}}}
    status "pending"

    trait :request_approved do
      status "approved"
    end

    trait :request_canceled do
      status "canceled"
    end

    trait :request_closed do
      status "closed"
    end

    trait :target100 do
      target_id 100
    end
  end

  factory(:log, :class => Approval::Log) do
    action "submit"
    action_by "portal.admin@mo.laxino.com"
    sequence(:approval_request_id)

    trait :log_approve do
      action "approve"
    end

    trait :log_publish do
      action "publish"
    end

    trait :log_cancel do
      action "cancel"
    end
  end
end
