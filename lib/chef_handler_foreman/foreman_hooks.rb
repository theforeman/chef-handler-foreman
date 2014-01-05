require 'chef_handler_foreman/foreman_facts'
require 'chef_handler_foreman/foreman_reporting'
require 'chef_handler_foreman/foreman_resource_reporter'
require 'chef_handler_foreman/foreman_uploader'

module ChefHandlerForeman
  module ForemanHooks
    # {:url => '', ...}
    def foreman_server_options(options)
      options = { :client_key => client_key || '/etc/chef/client.pem' }.merge(options)
      @foreman_uploader = ForemanUploader.new(options)
    end

    def foreman_facts_upload(upload)
      if upload
        foreman_facts_handler          = ForemanFacts.new
        foreman_facts_handler.uploader = @foreman_uploader
        report_handlers << foreman_facts_handler
        exception_handlers << foreman_facts_handler
      end
    end

    def foreman_reports_upload(upload, mode = 1)
      if upload
        case mode
          when 1
            foreman_reporter          = ForemanResourceReporter.new(nil)
            foreman_reporter.uploader = @foreman_uploader
            if Chef::Config[:event_handlers].is_a?(Array)
              Chef::Config[:event_handlers].push foreman_reporter
            else
              Chef::Config[:event_handlers] = [foreman_reporter]
            end
          when 2
            foreman_handler          = ForemanReporting.new
            foreman_handler.uploader = uploader
            report_handlers << foreman_handler
            exception_handlers << foreman_handler
          else
            raise ArgumentError, 'unknown mode: ' + mode.to_s
        end
      end
    end
  end
end
