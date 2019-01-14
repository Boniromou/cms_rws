Approval::Engine.routes.draw do

  get '/index' => 'requests#index'
  
  namespace :requests do
    get 'approved_index'
    scope ':id' do
      post 'approve'
      post 'cancel_submit'
      post 'cancel_approve'
    end
  end

  namespace :logs do
    get 'list'
  end

  namespace :internal do
    post '/submit' => 'requests#submit'
    post '/update_status' => 'requests#update_status'
    get '/get_details' => 'requests#get_details'
    get '/get_status_by_target_ids' => 'requests#get_status_by_target_ids'
    get '/get_details_by_target_ids' => 'requests#get_details_by_target_ids'
  end
end
