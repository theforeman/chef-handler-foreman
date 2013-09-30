# DESCRIPTION: 

This script is an alpha version of Chef report handler that send reports to TheForeman Project.
You need Foreman 1.3+ to use it.
See: http://www.theforeman.org

# Usage:

In /etc/chef/config.rb :
	
	require '/PATH/TO/lib/chef/handler/foreman.rb'
	foreman_handler = ForemanReporting.new({:foreman_url => 'https://foreman.example.com'})
	report_handlers << foreman_handler
	exception_handlers << foreman_handler	

