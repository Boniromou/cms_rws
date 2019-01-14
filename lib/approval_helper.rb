require 'csv'
require 'yaml'
require 'net/http'
require 'json'
require 'logger'
module Cronjob
class ApprovalHelper 
  def initialize(env)
      # Set up environment
      @env = env

      # Set up execute_by
      @executed_by = "system"
      
      # Deposit path
      @deposit_path = File.expand_path(File.dirname(__FILE__)) + '/deposit.yml'
      file_exist?(@deposit_path)
      @deposit_url = YAML.load_file(@deposit_path)[@env]
  end   
  
  def run
    @Approvetransaction = ApprovalRequest.where(status: :approved)
    p "==================="
    p @Approvetransaction
    p "===================="
    @Approvetransaction.each do | trx| 
      transaction = PlayerTransaction.find_by_id(trx.target_id)
      player = Player.find_by_id(transaction.player_id)
      p "!!!!!!!!!!!!"
      p transaction
      p player
      p "!!!!!!!!!!!!"
      data = {}
      data[:login_name] = player.member_id
      data[:amount] = transaction.amount / 100
      data[:ref_trans_id] = transaction.ref_trans_id
      data[:trans_date] = transaction.trans_date.localtime
      data[:source_type] = "cage_exception_transaction"
      data[:machine_token] = transaction.machine_token
      data[:casino_id] = transaction.casino_id
      data[:executed_by] = @executed_by
      transaction.approved_by = ApprovalLog.find_by_approval_request_id_and_action(trx.id, 'approve').action_by
      transaction.save
      if JSON.parse(trx.data)["transaction_type"] == "manual_deposit" 
        deposit_request(data)
        
      elsif JSON.parse(trx.data)["transaction_type"] == "manual_withdraw"
        withdraw_request(data)
      end
    end
     
    logger_output "==================================================================================================="
    logger_output "Run Finished, Fail Data as:"
    logger_output @failures
    
    
  end


  def deposit_request(data)
      path = @deposit_url + 'exception_deposit'
      logger_output "==================================================================================================="
      logger_output "Call Cage exception_deposit #{path} with parms:"
      logger_output data

      begin
          uri = URI.parse(path)
          response = Net::HTTP.post_form(uri,data)
          response = JSON.parse(response.body)
      rescue
          response = {"error_code" => "HttpConnectIssue"}
      end
      logger_output "\nResponse: #{response}"
      logger_output response
      handle_response(response, data)
  end

  def withdraw_request(data)
      path = @deposit_url + 'exception_withdraw'
      logger_output "==================================================================================================="
      logger_output "Call Cage exception_deposit #{path} with parms:"
      logger_output data

      begin
          uri = URI.parse(path)
          response = Net::HTTP.post_form(uri,data)
          response = JSON.parse(response.body)
      rescue
          response = {"error_code" => "HttpConnectIssue"}
      end
      logger_output "\nResponse: #{response}"
      logger_output response
      handle_response(response, data)
  end

  protected 
  def handle_response(response, data)
      if (response["error_code"].nil? || (response["error_code"]!="OK" && response["error_code"]!= "AlreadyProcessed"))
         abort("Somethings Fail, Bye")
      end
  end

  def file_exist?(path)
      if !File.exist?(path)
         logger_output FILE_NOT_EXIST_MESSAGE + path
         logger_output USAGE_MASSAGE
         exit
      end
  end

  def logger_output(line)
      puts line
  end
 end
end
