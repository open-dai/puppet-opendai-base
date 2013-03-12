require 'socket'
 
module Puppet::Parser::Functions
	newfunction(:get_ip_addr, :type => :rvalue) do |args|
		hostname = args[0].strip

			Socket::getaddrinfo(hostname,'www',nil,Socket::SOCK_STREAM)[0][3]
	end
end