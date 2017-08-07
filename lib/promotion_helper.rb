require 'csv'
require 'yaml'
require 'net/http'
require 'json'
require 'logger'

class InsertPromotion   
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
  
  def run(data)
      deposit_request(data)
  end

  def deposit_request(data)
      path = @deposit_url + 'internal_deposit'
      logger_output "==================================================================================================="
      logger_output "Call Cage internal_deposit #{path} with parms:"
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


class InsertPromotionWithFile < InsertPromotion
  def initialize(env, path, executed_by)
      # Set up environment
      @env = env

      # Set up insert csv path
      @path = path

      # Set up execute_by
      @executed_by = executed_by
      
      # Deposit path
      @deposit_path = File.expand_path(File.dirname(__FILE__)) + '/deposit.yml'
      file_exist?(@deposit_path)
      @deposit_url = YAML.load_file(@deposit_path)[@env]

      # Fail data
      @failures = []
  end

  def run
      # If promotion file not found then exit
      file_exist?(@path)

      # Parser For Each data
      CSV.foreach(@path) do |row|
          data = {}
          data[:login_name] = row[0]
          data[:casino_id] = row[1]
          data[:amt] = row[2]
          data[:promotion_code] = row[3]
          data[:source_type] = 'promotion_deposit'
          data[:executed_by] = @executed_by
          deposit_request(data)
      end
      logger_output "==================================================================================================="
      logger_output "Run Finished, Fail Data as:"
      logger_output @failures
  end
  
  protected
  def handle_response(response, data)
      if (response["error_code"].nil? || (response["error_code"]!="OK" && response["error_code"]!= "AlreadyProcessed"))
         @failures << data
      end
  end
  def logger_output(line)
      if line.is_a?(Array)
        puts JSON.pretty_generate(line)
      elsif line.is_a?(Hash)
        p line
      else
        puts line
      end
  end
end


