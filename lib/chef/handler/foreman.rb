require 'chef'
require 'chef/handler'
require 'net/http'
require 'net/https'
require 'uri'

class ForemanReporting < Chef::Handler
  
	def initialize ( opts = {})
		@options = {
			:foreman_url = 'http://foreman.fitzdsl.net:3000'
		}
	end

	def report
		Chef::Log.debug("Run status is #{run_status.inspect}")

		uri = URI.parse(options[:foreman_url])
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl     = uri.scheme == 'https'
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		req = Net::HTTP::Post.new("#{uri.path}/api/reports")
		req.add_field('Accept', 'application/json,version=2' )
		req.content_type = 'application/json'

		report = {}
		report['host'] = node.fqdn
		report['reported_at'] = Time.now.utc.to_s
		report_status = {}
		METRIC = %w[applied restarted failed failed_restarts skipped pending]
		METRIC.each do |m|
		        report_status[m] = 0
		end
		report['metrics'] = {}
		logs = []
		l = { 'log' => { 'sources' => {}, 'messages' => {} } }
		l['log']['level'] = 'notice'
		l['log']['messages']['message'] = run_status.inspect
		l['log']['sources']['source'] = 'Chef'
		logs << l
		report['logs'] = logs

		req.body = report.to_json
	end




