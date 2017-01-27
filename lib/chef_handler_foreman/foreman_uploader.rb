#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'net/http'
require 'net/https'
require 'uri'
require 'openssl'
require 'digest/sha2'
require 'base64'

module ChefHandlerForeman
  class ForemanUploader
    attr_reader :options

    def initialize(opts)
      @options = opts
    end

    def foreman_request(path, body, client_name, method = 'post')
      uri              = URI.parse(options[:url])
      http             = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      if http.use_ssl?
        if options[:foreman_ssl_ca] && !options[:foreman_ssl_ca].empty?
          http.ca_file     = options[:foreman_ssl_ca]
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end

        if options[:foreman_ssl_cert] && !options[:foreman_ssl_cert].empty? && options[:foreman_ssl_key] && !options[:foreman_ssl_key].empty?
          http.cert = OpenSSL::X509::Certificate.new(File.read(options[:foreman_ssl_cert]))
          http.key  = OpenSSL::PKey::RSA.new(File.read(options[:foreman_ssl_key]), nil)
        end
      end

      req = build_request(method, uri, path)
      req.add_field('Accept', 'application/json,version=2')
      req.add_field('X-Foreman-Client', client_name)
      req.body = body.to_json
      req.content_type = 'application/json'
      # signature can be computed once we set body and X-Foreman-Client
      req.add_field('X-Foreman-Signature', signature(req))
      response = http.request(req)
    end

    def build_request(method, uri, path)
      Net::HTTP.const_get(method.capitalize).new("#{uri.path}/#{path}")
    rescue NameError => e
      raise "unsupported method #{method}, try one of get, post, delete, put"
    end

    def signature(request)
      case request
        when Net::HTTP::Post, Net::HTTP::Patch, Net::HTTP::Put
          sign_data(request.body)
        when Net::HTTP::Get, Net::HTTP::Delete
          sign_data(request['X-Foreman-Client'])
        else
          raise "Don't know how to sign #{req.class} requests"
      end
    end

    def sign_data(data)
      hash_to_sign = Digest::SHA256.hexdigest(data)
      key = OpenSSL::PKey::RSA.new(File.read(options[:client_key]))
      # Base64.encode64 is adding \n in the string
      signature = Base64.encode64(key.sign(OpenSSL::Digest::SHA256.new, hash_to_sign)).gsub("\n",'')
    end
  end
end

