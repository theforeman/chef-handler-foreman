# Description

This gem adds Chef report and attributes handlers that send reports to TheForeman Project.
You need Foreman 1.3+ to use it.
See: http://www.theforeman.org

## Installation


Since it's released as a gem you can simply run this command under root
```sh
gem install chef_handler_foreman
```
## Usage:

In /etc/chef/config.rb:

```ruby
# this adds new functions to chef configuration
require 'chef_handler_foreman'
# here you can specify your connection options
foreman_server_options  :url => 'http://your.server/foreman'
# add following line if you want to upload node attributes (facts in Foreman language)
foreman_facts_upload    true
# add following line if you want to upload reports
foreman_reports_upload  true
# add following line to manage reports verbosity. Allowed values are debug, notice and error
reports_log_level       "notice"
```

You can also specify a second argument to foreman_reports_upload which is a number:
- 1 (default) for reporter based on more detailed ResourceReporter
- 2 not so verbose based just on run_status, actually just counts applied resources
