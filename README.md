# DESCRIPTION:

This script is an alpha version of Chef report handler that send reports to TheForeman Project.
You need Foreman 1.3+ to use it.
See: http://www.theforeman.org

# Usage:

In /etc/chef/config.rb:

	require '/PATH/TO/lib/chef/handler/foreman_reporting.rb'
	foreman_report_handler = ForemanReporting.new({:url => 'https://smart-proxy.example.com:8443'})
	report_handlers << foreman_report_handler
	exception_handlers << foreman_report_handler

To play with facts uploading you can just add fact reporter like this:

	require '/PATH/TO//lib/chef/handler/foreman_facts.rb'
	foreman_facts_handler = ForemanFacts.new({:url => 'http://smart-proxy.example.com:8443'})
	report_handlers << foreman_facts_handler
	exception_handlers << foreman_facts_handler

It's possible to change default chef-client's client.pem location using :
        foreman_report_handler = ForemanReporting.new({:url => 'https://smart-proxy.example.com:8443', , :client_key => '/custom/path/client.pem'})
