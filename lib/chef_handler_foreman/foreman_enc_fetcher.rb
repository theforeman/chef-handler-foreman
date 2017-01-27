require 'json'

module ChefHandlerForeman
  class ForemanEncFetcher < ::Chef::EventDispatch::Base
    SUPPORTED_LEVELS = %w(default force_default normal override force_override automatic)

    attr_accessor :uploader

    def initialize(level)
      super()
      raise "Unsupported node attributes level #{level}, use one of #{SUPPORTED_LEVELS.join(', ')}" unless SUPPORTED_LEVELS.include?(level)
      @attributes_level = level
    end

    def node_load_completed(node)
      client_name = node.name
      result = Chef::Config.foreman_uploader.foreman_request("/api/enc/#{client_name}", client_name, client_name, 'get')
      begin
        enc = JSON.parse(result.body)
      rescue => e
        Chef::Log.error "Foreman ENC could not be fetched because of #{e.class}: #{e.message}"
	return false
      end

      enc['parameters'].each do |parameter, value|
        nested_parts = parameter.split('::')
        nest = nested_parts[0..-2].inject(node.send(@attributes_level)) { |attributes_nest, attribute| attributes_nest[attribute] }
        nest[nested_parts[-1]] = type_cast(value)
      end
    end

    def type_cast(value)
      case value
      when 'false'
        false
      when 'true'
        true
      else
        value
      end
    end
  end
end
