# Print the certificate chain a host presents, with each certificate's
# issuer and its AIA "CA Issuers" URL. Diagnostic only: verification is
# off for this handshake so an incomplete chain can be inspected; nothing
# is fetched over it.
#
#   ruby research/texas-tech-letters/cert_chain.rb vva.vietnam.ttu.edu
require "openssl"
require "socket"

host = ARGV.fetch(0)
ctx = OpenSSL::SSL::SSLContext.new
ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
tcp = TCPSocket.new(host, 443)
ssl = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
ssl.hostname = host
ssl.connect
ssl.peer_cert_chain.each_with_index do |c, i|
  aia = c.extensions.find { |e| e.oid == "authorityInfoAccess" }&.value
  puts "#{i}: subject #{c.subject}", "   issuer  #{c.issuer}", "   expires #{c.not_after}", "   aia     #{aia&.gsub("\n", ' | ')}"
end
ssl.close
tcp.close
