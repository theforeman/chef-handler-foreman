#! /usr/bin/env ruby
#

require 'json'
require 'time'
require 'net/http'
require 'net/https'
require 'uri'


report = {}
report['host'] = 'test-node.fitzdsl.net'
report['reported_at'] = Time.now.utc.to_s
time = Time.parse(report['reported_at']).utc
report_status = {}
METRIC = %w[applied restarted failed failed_restarts skipped pending]
METRIC.each do |m|
	report_status[m] = 0
end
report['status'] = report_status
metrics = {}
metrics['applied'] = 1
metrics['restarted'] = 0
metrics['failed'] = 0
metrics['failed_restarts'] = 0
metrics['skipped'] = 0
metrics['pending'] = 0
report['metrics'] =  metrics
logs = []
l = { 'log' => { 'sources' => {}, 'messages' => {} } }
l['log']['level'] = 'notice'
l['log']['messages']['message'] = 'Chef installed this...'
l['log']['sources']['source'] = 'Chef'
logs << l
report['logs'] = logs
full_report = { 'report' => report }

puts full_report.to_s


foreman_url = 'http://foreman.fitzdsl.net:3000'
uri = URI.parse(foreman_url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl     = uri.scheme == 'https'
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
req = Net::HTTP::Post.new("#{uri.path}/api/reports")
req.add_field('Accept', 'application/json,version=2' )
req.content_type = 'application/json'
req.body         =  full_report.to_json
puts req.body.to_s
response = http.request(req)
