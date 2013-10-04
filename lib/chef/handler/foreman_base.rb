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
    @options = {}
    @options.merge! opts
  end

  private

  def foreman_request(path, body)
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
    req.body         = body.to_json
    response         = http.request(req)
  end
end
