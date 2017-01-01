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

In /etc/chef/client.rb:

```ruby
# this adds new functions to chef configuration
require 'chef_handler_foreman'
# here you can specify your connection options
foreman_server_options  :url => 'http://your.server/foreman'
# Or another option to set URL if using chef-client cookbook config option
foreman_server_url 'http://foreman.domain.com'
# add following line if you want to upload node attributes (facts in Foreman language)
foreman_facts_upload    true
## Facts whitelist / blacklisting
# add following line if you want to upload only specific node attributes - only top-level attributes
foreman_facts_whitelist ['lsb','network','cpu']
# add following line if you want to avoid uploading specific node attributes - any part from the key will do
foreman_facts_blacklist ['kernel','counters','interfaces::sit0']
# enable caching of attributes - (full) upload will be performed only if attributes changed
foreman_facts_cache_file '/var/cache/chef_foreman_cache.md5'
# add following line if you want to upload reports
foreman_reports_upload  true
# add following line to manage reports verbosity. Allowed values are debug, notice and error
reports_log_level       "notice"
```

### Using Chef-Client Cookbook

You can utilize the [Chef-Client](https://github.com/chef-cookbooks/chef-client) Cookbook to setup your client.rb

With a Role

```json
"chef_client": {
  "chef_server_url": "https://chef.domain.com",
  "config": {
    "foreman_server_url": "https://foreman.domain.com",
    "foreman_facts_upload": true,
    "foreman_reports_upload": true,
    "reports_log_level": "notice"
  }
}
```

With attributes

```ruby
node['chef_client']['config']['foreman_server_url'] = 'https://foreman.domain.com'
node['chef_client']['config']['foreman_facts_upload'] = true
node['chef_client']['config']['foreman_reports_upload'] = true
node['chef_client']['config']['reports_log_level'] = 'notice'
```


You can also specify a second argument to foreman_reports_upload which is a number:
- 1 (default) for reporter based on more detailed ResourceReporter
- 2 not so verbose based just on run_status, actually just counts applied resources

## Chef 10 support

Chef 10 is generally supported from version 0.0.6 and above. However you must set
foreman_reports_upload mode to 2 manually. We can't get detailed reports in old 
chef. The configuration line will look like this:

```ruby
foreman_reports_upload  true, 2
```

### Caching of facts

Note that some attributes, such as network counters or used memory, change on every chef-client run.
For caching to work, you would need to blacklist such attributes, otherwise facts will be uploaded
on every run.

## Facts whitelisting / blacklisting

Cherry picking which facts to upload, coupled with caching, allows to scale the solution to many
thousands of nodes. Note, however, that some attributes are expected by Foreman to exist, and thus
should not be blacklisted. The whitelist and blacklist examples above include a minimal set of
attributes known to work in a large scale production environment.

Note that the order of config options matter. Blacklist/whitelist must be below foreman_facts_upload
line.

