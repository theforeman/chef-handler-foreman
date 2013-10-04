# DESCRIPTION: 

This script is an alpha version of Chef report handler that send reports to TheForeman Project.
You need Foreman 1.3+ to use it.
See: http://www.theforeman.org

# Usage:

In /etc/chef/config.rb:

	require '/PATH/TO/lib/chef/handler/foreman_reporting.rb'
	foreman_handler = ForemanReporting.new({:url => 'https://foreman.example.com'})
	report_handlers << foreman_handler
	exception_handlers << foreman_handler	

To play with facts uploading you can just add fact reporter like this:

	require '/PATH/TO//lib/chef/handler/foreman_facts.rb'
	foreman_facts_handler = ForemanFacts.new({:url => 'http://foreman.example.com'})
	report_handlers << foreman_facts_handler
	exception_handlers << foreman_facts_handler


