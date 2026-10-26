# Download an intermediate CA certificate from its AIA URL, check that it
# verifies against the system roots, and that it signed the host's leaf,
# then write it as PEM. This is how this-day/config/certs/InCommonRSAServerCA2.pem
# was made (the URL is the AIA "CA Issuers" entry that cert_chain.rb prints):
#
#   ruby research/texas-tech-letters/get_intermediate.rb \
#     http://crt.sectigo.com/InCommonRSAServerCA2.crt vva.vietnam.ttu.edu \
#     this-day/config/certs/InCommonRSAServerCA2.pem
require "openssl"
require "socket"
require_relative "../../this-day/lib/this_day/archive/fetcher"

url, host, out = ARGV
r = ThisDay::Archive::Fetcher.new.fetch(url)
abort "fetch failed: #{r.code} #{r.error}" unless r.ok?
cert = OpenSSL::X509::Certificate.new(r.body)

roots = OpenSSL::X509::Store.new
roots.set_default_paths
abort "intermediate does not verify against system roots: #{roots.error_string}" unless roots.verify(cert)

ctx = OpenSSL::SSL::SSLContext.new
ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
tcp = TCPSocket.new(host, 443)
ssl = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
ssl.hostname = host
ssl.connect
leaf = ssl.peer_cert
ssl.close
tcp.close
abort "intermediate did not sign #{host}'s certificate" unless leaf.verify(cert.public_key)

File.write(out, cert.to_pem)
puts "#{cert.subject}", "issuer #{cert.issuer}", "expires #{cert.not_after}", "sha256 #{OpenSSL::Digest::SHA256.hexdigest(cert.to_der)}", "wrote #{out}"
