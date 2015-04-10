require "net/http"
require "uri"
require 'json'

module UserManagement
  def self.authenticate(username, password)
    uri = URI.parse("#{SSO_URL}/internal/system_user_sessions")
    http = Net::HTTP.new(uri.host, uri.port)
    http.set_debug_output($stdout)

    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data({"system_user[username]" => username, "system_user[password]" => password, "authenticity_token" => Time.now.to_f, 'app_name' => APP_NAME})
    response = http.request(request)
    return JSON.parse(response.body)
  end
end
