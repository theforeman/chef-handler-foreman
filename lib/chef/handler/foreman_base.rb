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

require 'chef'
require 'chef/handler'
require 'net/http'
require 'net/https'
require 'uri'

class ForemanBase < Chef::Handler
  attr_reader :options

  def initialize(opts = {})
    #Default report values
    @options = { :client_key => '/etc/chef/client.pem'}
    @options.merge! opts
  end

  private

  def foreman_request(path, body,client_name)
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

    req = Net::HTTP::Post.new("#{uri.path}/#{path}")
    req.add_field('Accept', 'application/json,version=2')
    req.content_type = 'application/json'
    body_json        = body.to_json
    req.body         = body_json
    req.add_field('X-Foreman-Signature',sign_request(body_json,options[:client_key]))
    req.add_field('X-Foreman-Client',client_name)
    response         = http.request(req)
  end

  def sign_request(body_json,key_path = '/etc/chef/client.pem')
     require 'openssl'
     require 'digest/sha2'
     require 'base64'
     hash_body = Digest::SHA256.hexdigest(body_json)
     key = OpenSSL::PKey::RSA.new(File.read(key_path))
     # Base64.encode64 is adding \n in the string
     signature = Base64.encode64(key.sign(OpenSSL::Digest::SHA256.new,hash_body)).gsub("\n",'')
   end

end
