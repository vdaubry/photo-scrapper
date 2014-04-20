require_relative 'generic_host'
require_relative 'host1'
require_relative 'host2'

class HostFactory
  def self.create_with_host_url(url)
    puts "HostFactory: searching host at = #{url}"

    host = nil
    hosts = YAML.load_file("private-conf/hosts_conf.yml")["hosts"]
    begin
      host = URI.parse(url).host
    rescue URI::InvalidURIError => e
      puts e.to_s
    end

    return nil if host.nil?
    matched_host = hosts.select {|h| host.downcase.include?(h)}.first
    if matched_host
      host_class = YAML.load_file("private-conf/hosts_conf.yml")[matched_host]
      Object.const_get(host_class).new(url)
    else 
      GenericHost.new(url)
    end
  end
end