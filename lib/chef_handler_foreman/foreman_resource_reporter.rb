module ChefHandlerForeman
  class ForemanResourceReporter < ::Chef::ResourceReporter
    attr_accessor :uploader, :log_level

    def initialize(*args)
      @total_up_to_date     = 0
      @total_skipped        = 0
      @total_updated        = 0
      @total_failed         = 0
      @total_restarted      = 0
      @total_failed_restart = 0
      @all_resources        = []
      super
    end

    def run_started(run_status)
      @run_status = run_status
    end

    def run_completed(node)
      @status = "success"
      post_reporting_data
    end

    def run_failed(exception)
      @exception = exception
      @status    = "failure"
      # If we failed before we received the run_started callback, there's not much we can do
      # in terms of reporting
      if @run_status
        post_reporting_data
      end
    end

    def resource_current_state_loaded(new_resource, action, current_resource)
      super
      @all_resources.push @pending_update unless @pending_update.nil?
    end


    def resource_up_to_date(new_resource, action)
      @total_up_to_date += 1
      super
    end

    def resource_skipped(resource, action, conditional)
      @total_skipped += 1
      super
    end

    def resource_updated(new_resource, action)
      @total_updated   += 1
      @total_restarted += 1 if action.to_s == 'restart'
      super
    end

    def resource_failed(new_resource, action, exception)
      @total_failed         += 1
      @total_failed_restart += 1 if action.to_s == 'restart'
      super
    end

    def resource_completed(new_resource)
      if @pending_update && !nested_resource?(new_resource)
        @pending_update.finish
        @updated_resources << @pending_update
        @pending_update = nil
      end
    end

    def post_reporting_data
      if reporting_enabled?
        run_data = prepare_run_data
        Chef::Log.info("Sending resource update report to foreman (run-id: #{@run_id})")
        Chef::Log.debug run_data.inspect
        begin
          Chef::Log.debug("Sending data...")
          if uploader
            uploader.foreman_request('/api/reports', { "report" => run_data }, node_name)
          else
            Chef::Log.error "No uploader registered for foreman reporting, skipping report upload"
          end
        rescue => e
          Chef::Log.error "Sending failed with #{e.class} #{e.message}"
          Chef::Log.error e.backtrace.join("\n")
        end
      else
        Chef::Log.debug("Reporting disabled, skipping report upload")
      end
    end

    def prepare_run_data
      run_data                = {}
      run_data["host"]        = node_name
      run_data["reported_at"] = end_time.to_s
      run_data["status"]      = resources_per_status

      run_data["metrics"] = {
          "resources" => { "total" => @total_res_count },
          "time"      => resources_per_time
      }

      run_data["logs"] = filter_logs(resources_logs + [chef_log])
      run_data
    end

    def resources_per_status
      { "applied"         => @total_updated,
        "restarted"       => @total_restarted,
        "failed"          => @total_failed,
        "failed_restarts" => @total_failed_restart,
        "skipped"         => @total_skipped,
        "pending"         => 0
      }
    end

    def resources_per_time
      @run_status.all_resources.inject({}) do |memo, resource|
        name, time = resource.resource_name.to_s, resource.elapsed_time || 0
        memo[name] = memo[name] ? memo[name] + time : time
        memo
      end
    end

    def resources_logs
      @all_resources.map do |resource|
        action  = resource.new_resource.action
        message = action.is_a?(Array) ? action.first.to_s : action.to_s
        message = format_message(message, resource.new_resource)
        message += " (#{resource.exception.class} #{resource.exception.message})" unless resource.exception.nil?
        level   =  resource_level(resource)
        { "log" => {
            "sources"  => { "source" => resource.new_resource.to_s },
            "messages" => { "message" => message },
            "level"    => level
        } }
      end
    end

    def format_message(message, resource)
      case resource.resource_name.to_s
        when 'template', 'cookbook_file'
          message += " with diff "+resource.diff unless resource.diff.nil?
        when 'package'
          message += " package in #{resource.version}" unless resource.version.nil?
        else
          message = resource.action.to_s
      end
      message
    end

    def resource_level(resource)
      if ! resource.exception.nil?
        return 'err'
      elsif resource.new_resource.updated
        return 'notice'
      else
        return 'debug'
      end
    end

    def chef_log
      message = 'run'
      if @status == 'success' && exception.nil?
        level = 'notice'
      else
        message += " (#{exception.class} #{exception.message})"
        level   = 'err'
      end

      { "log" => {
          "sources"  => { "source" => 'Chef' },
          "messages" => { "message" => message },
          "level"    => level
      } }
    end

    # currently we support only three log levels:
    #  'debug' means do not filter,
    #  'notice' updated resources and errors
    #  'error' means only errors

    def filter_logs(logs)
      if log_level == 'error'
        logs.select { |log| log['log']['level'] == 'err' }
      elsif log_level == 'notice'
        logs.select { |log| ['err','notice'].include? log['log']['level'] }
      else
        logs
      end
    end

  end
end
