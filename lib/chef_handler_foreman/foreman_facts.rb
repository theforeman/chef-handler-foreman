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

module ChefHandlerForeman
  class ForemanFacts < Chef::Handler
    attr_accessor :uploader

    def report
      send_attributes(prepare_facts)
    end

    private

    def prepare_facts
      os      = node.lsb[:id] || node.platform
      release = node.lsb[:release] || node.platform_version

      # operatingsystem and operatingsystemrelase are not needed since foreman_chef 0.1.3
      { :name  => node.name,
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

    # if node.lsb[:id] fails and we use platform instead, normalize os names
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
      plainify(attributes.to_hash).flatten.inject(&:merge)
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
          new[get_key(key, prefix)] = value
          result.push new
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
      if uploader
        uploader.foreman_request('/api/hosts/facts', attributes, node.name)
      else
        Chef::Log.error "No uploader registered for foreman facts, skipping facts upload"
      end
    end
  end
end
