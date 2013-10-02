class ForemanFacts < Chef::Handler
  attr_reader :options

  def initialize(opts = {})
    #Default report values
    @options = {}
    @options.merge! opts
  end

  def report
    send_attributes(prepare_facts)
  end

  private

  def prepare_facts
    { :name  => node.name,
      :facts => plain_attributes.merge({
                                           :operatingsystem        => node.lsb.id,
                                           :operatingsystemrelease => node.lsb.release,
                                           :_timestamp             => Time.now.to_i
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
    [prefix, key].compact.join('_')
  end

  def send_attributes(attributes)
    uri              = URI.parse(options[:foreman_url])
    http             = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE


    if http.use_ssl?
      if options[:foreman_ssl_ca] && !options[:foreman_ssl_ca].empty?
        http.ca_file     = options[:foreman_ssl_ca]
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      else
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      if options[:foreman_ssl_cert] && !options[:foreman_ssl_cert].empty? && options[:foreman_ssl_key] && !options[:foreman_ssl_key].empty?
        http.cert = OpenSSL::X509::Certificate.new(File.read(options[:foreman_ssl_cert]))
        http.key  = OpenSSL::PKey::RSA.new(File.read(options[:foreman_ssl_key]), nil)
      end
    end
    req = Net::HTTP::Post.new("#{uri.path}/api/hosts/facts")
    req.add_field('Accept', 'application/json,version=2')
    req.content_type = 'application/json'
    req.body         = attributes.to_json
    response         = http.request(req)
  end
end

