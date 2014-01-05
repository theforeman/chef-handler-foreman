require "chef_handler_foreman/version"
require 'chef'
require 'chef_handler_foreman/foreman_hooks'

Chef::Config.send :extend, ChefHandlerForeman::ForemanHooks
