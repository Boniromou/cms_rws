require 'openssl'
require 'base64'

module LaxSupport

  module AuthorizedRWS
    module Authentication
      LAXRWS_HEADER_PREFIX = 'x-lax-'
      DEFAULT_HEADERS = [ 'content-type', 'content-md5', 'date' ]
      INTERESTING_HEADERS = [ /(content[-_]type)/io, /(content[-_]md5)/io, /(date)/io, /(x[-_]lax[-_].+)/io ]
 
      # Calculate authorization signature 
      def signature(secret_access_key, path, http_method=:get, headers={}) 
        signed_string = sign(canonicalize(http_method, path, headers), secret_access_key)
      end

      protected
 
      # Canonicalize the given request attributes 
      def canonicalize(http_method, path, headers) 
        # Start out with default values of all the interesting headers
        sign_headers = {}
        DEFAULT_HEADERS.each { |header| sign_headers[header] = '' }

        # Copy in any acutal values, 
        # including values for custom LaxRWS headers
        headers.each do |header, value|
          header = header.downcase # Can't modify frozen string so no bang
          if INTERESTING_HEADERS.any? { |key| key === header }
            # Normalize header by replacing underscore with dash
            header = $1.gsub(/_/, '-')
            sign_headers[header] = value.to_s.strip 
          end
        end

        # Now we start building the canonical string for this request
        canonical = http_method.to_s.upcase + "\n"
  
        # Sort the headers by name, and append them (just the values)
        # to the string to be signed
        sign_headers.sort_by { |h| h[0] }.each do |header, value|
          canonical << header << ':' if header =~ /^#{LAXRWS_HEADER_PREFIX}/io
          canonical << value << "\n"
        end
  
        # The final part of the canonical string to be signed is the URI path
        canonical << path
      end
   
      # Calculate keyed-HMAC for the canonicalized string 
      def sign(canonical_string, secret_access_key) 
        Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret_access_key, canonical_string)).strip
      end

    end
  end
end

