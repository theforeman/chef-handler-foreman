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
require 'digest/md5'

module ChefHandlerForeman
  class ForemanFacts < Chef::Handler
    attr_accessor :uploader
    attr_accessor :blacklist
    attr_accessor :whitelist
    attr_accessor :cache_file
    attr_accessor :cache_expired

    def report
      send_attributes(prepare_facts)
    end


    private

    def prepare_facts
      return false if node.nil?

      os, release = nil
      if node.respond_to?(:lsb)
        os = node['lsb']['id']
        release = node['lsb']['release']
      end
      os ||= node['platform']
      release ||= node['platform_version']

      # operatingsystem and operatingsystemrelase are not needed since foreman_chef 0.1.3
      { :name  => node.name.downcase,
        :facts => plain_attributes.merge({
                                             :environment            => node.chef_environment,
                                             :chef_node_name         => node.name,
                                             :operatingsystem        => normalize(os),
                                             :operatingsystemrelease => release,
                                             :_timestamp             => Time.now,
                                             :_type                  => 'foreman_chef'
                                         })
      }
    end

    # if node['lsb']['id'] fails and we use platform instead, normalize os names
    def normalize(os)
      case os
      when 'redhat'
        'RedHat'
      when 'centos'
        'CentOS'
      else
        os.capitalize
      end
    end

    def plain_attributes
      # chef 10 attributes can be access by to_hash directly, chef 11 uses attributes method
      attributes = node.respond_to?(:attributes) ? node.attributes : node.to_hash
      attributes = attributes.select { |key, value| @whitelist.include?(key) } if @whitelist
      attrs = plainify(attributes.to_hash).flatten.inject(&:merge)
      verify_checksum(attrs) if @cache_file
      attrs
    end

    def plainify(hash, prefix = nil)
      result = []
      hash.each_pair do |key, value|
        if value.is_a?(Hash)
          result.push plainify(value, get_key(key, prefix))
        elsif value.is_a?(Array)
          result.push plainify(array_to_hash(value), get_key(key, prefix))
        else
          new                       = {}
          full_key = get_key(key, prefix)
          if @blacklist.nil? || !@blacklist.any? { |black_key| full_key.include?(black_key) }
            new[full_key] = value
            result.push new
          end
        end
      end
      result
    end

    def array_to_hash(array)
      new = {}
      array.each_with_index { |v, index| new[index.to_s] = v }
      new
    end

    def get_key(key, prefix)
      [prefix, key].compact.join('::')
    end

    def send_attributes(attributes)
      if @cache_file and !@cache_expired
        Chef::Log.info "No attributes have changed - not uploading to foreman"
      elsif !attributes
        Chef::Log.info "No attributes received, failed run - not uploading to foreman"
      else
        if uploader
          Chef::Log.info 'Sending attributes to foreman'
          Chef::Log.debug attributes.inspect
          uploader.foreman_request('/api/hosts/facts', attributes, node.name)
        else
          Chef::Log.error "No uploader registered for foreman facts, skipping facts upload"
        end
      end
    end

    def verify_checksum(attributes)
      @cache_expired = true
      attrs_checksum = Digest::MD5.hexdigest(attributes.to_s)
      if File.exist?(@cache_file)
        contents = File.read(@cache_file)
        if attrs_checksum == contents
          @cache_expired = false
        end
      end
      File.open(@cache_file, 'w') { |f| f.write(attrs_checksum) }
    rescue => e
      @cache_expired = true
      Chef::Log.info "unable to verify cache checksum - #{e.message}, facts will be sent"
      Chef::Log.debug e.backtrace.join("\n")
    end
  end
end
