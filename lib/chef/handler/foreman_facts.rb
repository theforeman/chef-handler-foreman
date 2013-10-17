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

require "#{File.dirname(__FILE__)}/foreman_base"

class ForemanFacts < ForemanBase
  def report
    send_attributes(prepare_facts)
  end

  private

  def prepare_facts
    { :name  => node.name,
      :facts => plain_attributes.merge({
                                           :operatingsystem        => node.lsb[:id],
                                           :operatingsystemrelease => node.lsb.release,
                                           :_timestamp             => Time.now
                                       })
    }
  end

  def plain_attributes
    plainify(node.attributes.to_hash).flatten.inject(&:merge)
  end

  def plainify(hash, prefix = nil)
    result = []
    hash.each_pair do |key, value|
      if value.is_a?(Hash)
        result.push plainify(value, get_key(key, prefix))
      elsif value.is_a?(Array)
        result.push plainify(array_to_hash(value), get_key(key, prefix))
      else
        new = {}
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
    foreman_request('/api/hosts/facts', attributes)
  end
end

