require "socket"

server = TCPServer.new("localhost", 3003)
loop do
  client = server.accept

  request_line = client.gets
  next if !request_line || request_line =~ /favicon/
  puts request_line

  client.puts "HTTP/1.1 200 OK\r\n\r\n"
  client.puts "Content-Type: text/plain\r\n\r\n"

  client.puts request_line
  client.puts rand(6) + 1
  client.close
end

# http://localhost:3003/?rolls=2&sides=6