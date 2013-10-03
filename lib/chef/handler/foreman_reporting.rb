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

require "#{File.dirname(__FILE__)}/foreman_base"

class ForemanReporting < ForemanBase

  METRIC = %w[restarted failed failed_restarts skipped pending]

  def report
    report                = {}
    report['host']        = node.fqdn
    report['reported_at'] = Time.now.utc.to_s
    report_status         = {}
    METRIC.each do |m|
      report_status[m] = 0
    end
    if failed?
      report_status['failed'] = 1
    end
    report_status['applied'] = run_status.updated_resources.count
    report['status']         = report_status

    # I compute can't compute much metrics for now
    metrics                  = {}
    metrics['resources']     = { 'total' => run_status.all_resources.count }
    times                    = {}
    run_status.all_resources.each do |resource|
      resource_name = resource.resource_name
      if times[resource_name].nil?
        times[resource_name] = resource.elapsed_time
      else
        times[resource_name] += resource.elapsed_time
      end
    end
    metrics['time']   =times.merge!({ 'total' => run_status.elapsed_time })
    report['metrics'] = metrics

    logs = []
    run_status.updated_resources.each do |resource|

      l                 = { 'log' => { 'sources' => {}, 'messages' => {} } }
      l['log']['level'] = 'notice'

      case resource.resource_name.to_s
        when 'template', 'cookbook_file'
          message = resource.diff
        when 'package'
          message = "Installed #{resource.package_name} package in #{resource.version}"
        else
          message = resource.action.to_s
      end
      l['log']['messages']['message'] = message
      l['log']['sources']['source']   = [resource.resource_name.to_s, resource.name].join(' ')
      #Chef::Log.info("Diff is #{l['log']['messages']['message']}")
      logs << l
    end

    # I only set failed to 1 if chef run failed
    if failed?
      l                               = { 'log' => { 'sources' => {}, 'messages' => {} } }
      l['log']['level']               = 'err'
      l['log']['sources']['source']   = 'chef'
      l['log']['messages']['message'] = run_status.exception
      logs << l
    end

    report['logs'] = logs
    full_report    = { 'report' => report }

    send_report(full_report)
  end

  private

  def send_report(report)
    foreman_request('/api/reports', report)
  end
end


