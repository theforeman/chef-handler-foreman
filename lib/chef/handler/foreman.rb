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

class ForemanReporting < Chef::Handler
        attr_reader :options 
	def initialize ( opts = {})
		#Default report values
		@options = {}
		@options.merge! opts
	end
	
	METRIC = %w[restarted failed failed_restarts skipped pending]
	def report

		report = {}
		report['host'] = node.fqdn
		report['reported_at'] = Time.now.utc.to_s
		report_status = {}
		METRIC.each do |m|
		        report_status[m] = 0
		end
		if failed?
			report_status['failed'] = 1
		end
		report_status['applied'] = run_status.updated_resources.count
		report['status'] = report_status

		# I compute can't compute much metrics for now
		metrics = {}
		metrics['resources'] = { 'total' => run_status.all_resources.count }
                times = {}
		run_status.all_resources.each do |resource|
			if times[resource.class.to_s].nil?
				times[resource.class.to_s] = resource.elapsed_time
			else
				times[resource.class.to_s] += resource.elapsed_time
			end
		end
		metrics['time']=times.merge!({ 'total' => run_status.elapsed_time })
		report['metrics'] =  metrics

		logs = []
		run_status.updated_resources.each  do |resource|
			l = { 'log' => { 'sources' => {}, 'messages' => {} } }
			l['log']['level'] = 'notice'
			l['log']['messages']['message'] = resource.action.to_s
			l['log']['sources']['source'] = [resource.class.to_s,resource.name].join(' ')
			logs << l
		end

		# I only set failed to 1 if chef run failed
		if failed?
			l = { 'log' => { 'sources' => {}, 'messages' => {} } }
			l['log']['level'] = 'err'
			l['log']['sources']['source'] = 'chef'
			l['log']['messages']['message'] = run_status.exception
			logs << l
		end

		report['logs'] = logs
		full_report =  { 'report' => report}

		Chef::Log.info("Report is #{full_report.inspect}")

		send_report(full_report)
	end

	private

	def send_report (report)
		uri = URI.parse(options[:foreman_url])
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl     = uri.scheme == 'https'
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE


		if http.use_ssl?
			if options[:foreman_ssl_ca] && !options[:foreman_ssl_ca].empty?
			  http.ca_file = options[:foreman_ssl_ca]
			  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
			else
			  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			end
			if options[:foreman_ssl_cert] && !options[:foreman_ssl_cert].empty? && options[:foreman_ssl_key] && !options[:foreman_ssl_key].empty?
			  http.cert = OpenSSL::X509::Certificate.new(File.read(options[:foreman_ssl_cert]))
			  http.key  = OpenSSL::PKey::RSA.new(File.read(options[:foreman_ssl_key]), nil)
			end
		end
		req = Net::HTTP::Post.new("#{uri.path}/api/reports")
		req.add_field('Accept', 'application/json,version=2' )
		req.content_type = 'application/json'
		req.body = report.to_json
		response = http.request(req)
	end
end


