require 'ipaddr'

module Puppet::Parser::Functions
  newfunction(:find_ip_in_subnet, :type => :rvalue, :doc =>
  "Find the IP on a node's interface that is within a given subnet.") do |args|
    debug "arg[0]: #{args[0]}"
    cidr = IPAddr.new(args[0])
    interfaces = lookupvar('interfaces').split(",")
    debug "interfaces: #{interfaces}"
    correct_ip = "127.0.0.1"
    interfaces.each do |int|
      debug "int: #{int}"
      ip = lookupvar("ipaddress_#{int}")
      debug "ip: #{ip}"
      begin
        if cidr.include?(ip) == true
          correct_ip = ip
          debug "correct_ip: #{correct_ip}"
        end
      rescue
        raise Puppet::ParseError, "Unexpected error in find_ip_in_subnet custom puppet function."
      end
    end
    if defined?(correct_ip) == nil
      function_warning(["No IP on this system is in the provided subnet. Defaulting to 127.0.0.1"])
    end
    debug "final_ip: #{correct_ip}"
    final_ip=correct_ip
  end
end
