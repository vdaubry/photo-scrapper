require_relative 'generic_host'
require_relative 'host1'

class HostFactory
  def self.create_with_host_url(url)
    hosts = YAML.load_file("hosts/hosts_conf.yml")["hosts"]
    host = URI.parse(url).host
    return nil if host.nil?

    matched_host = hosts.select {|h| host.downcase.include?(h)}.first
    if matched_host
      host_class = YAML.load_file("hosts/hosts_conf.yml")[matched_host]
      Object.const_get(host_class).new(url)
    else 
      GenericHost.new(url)
    end
  end
end