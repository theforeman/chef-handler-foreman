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

require 'chef/handler'

module ChefHandlerForeman
  class ForemanReporting < ::Chef::Handler
    attr_accessor :uploader

    def report
      report                   = { 'host' => node.fqdn, 'reported_at' => Time.now.utc.to_s }
      report_status            = Hash.new(0)


      report_status['failed']  = 1 if failed?
      report_status['applied'] = run_status.updated_resources.count
      report['status']         = report_status

      # I can't compute much metrics for now
      metrics                  = {}
      metrics['resources']     = { 'total' => run_status.all_resources.count }

      times = {}
      run_status.all_resources.each do |resource|
        resource_name = resource.resource_name
        if times[resource_name].nil?
          times[resource_name] = resource.elapsed_time
        else
          times[resource_name] += resource.elapsed_time
        end
      end
      metrics['time']   = times.merge!({ 'total' => run_status.elapsed_time })
      report['metrics'] = metrics

      logs = []
      run_status.updated_resources.each do |resource|
        l = { 'log' => { 'sources' => {}, 'messages' => {}, 'level' => 'notice' } }

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
        logs << {
            'log' => {
                'sources'  => { 'source' => 'chef' },
                'messages' => { 'message' => run_status.exception },
                'level'    => 'err' }
        }
      end

      report['logs'] = logs
      full_report    = { 'report' => report }

      send_report(full_report)
    end

    private

    def send_report(report)
      if uploader
        uploader.foreman_request('/api/reports', report, node.name)
      else
        Chef::Log.error "No uploader registered for foreman reporting, skipping report upload"
      end

    end
  end
end
