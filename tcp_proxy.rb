#!/usr/bin/env ruby
require 'socket'
require 'logger'
require 'optparse'

class TCPProxy
  def initialize(local_port: 3000, remote_port: 30000, remote_host: 'localhost')
    @local_port = local_port
    @remote_port = remote_port
    @remote_host = remote_host
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def start
    server = TCPServer.new(@local_port)
    @logger.info "TCP Proxy started on port #{@local_port}, forwarding to #{@remote_host}:#{@remote_port}"
    @logger.info "Press Ctrl+C to stop"

    trap('INT') do
      @logger.info "Shutting down..."
      server.close
      exit
    end

    loop do
      client_socket = server.accept
      Thread.new(client_socket) do |client|
        handle_connection(client)
      end
    end
  rescue Errno::EADDRINUSE
    @logger.error "Port #{@local_port} is already in use"
    exit 1
  rescue => e
    @logger.error "Error starting proxy: #{e.message}"
    exit 1
  end

  private

  def handle_connection(client)
    client_info = "#{client.peeraddr[3]}:#{client.peeraddr[1]}"
    @logger.info "New connection from #{client_info}"

    begin
      # Connect to the remote server
      remote = TCPSocket.new(@remote_host, @remote_port)
      @logger.info "Connected to #{@remote_host}:#{@remote_port} for client #{client_info}"

      # Create two threads for bidirectional data transfer
      threads = []

      # Client -> Remote
      threads << Thread.new do
        begin
          loop do
            data = client.recv(4096)
            break if data.empty?
            remote.write(data)
            remote.flush
          end
        rescue => e
          @logger.debug "Client->Remote error: #{e.message}"
        ensure
          remote.close_write rescue nil
        end
      end

      # Remote -> Client
      threads << Thread.new do
        begin
          loop do
            data = remote.recv(4096)
            break if data.empty?
            client.write(data)
            client.flush
          end
        rescue => e
          @logger.debug "Remote->Client error: #{e.message}"
        ensure
          client.close_write rescue nil
        end
      end

      # Wait for both threads to complete
      threads.each(&:join)

    rescue Errno::ECONNREFUSED
      @logger.error "Connection refused to #{@remote_host}:#{@remote_port}"
    rescue => e
      @logger.error "Error handling connection: #{e.class} - #{e.message}"
    ensure
      client.close rescue nil
      remote.close rescue nil
      @logger.info "Connection closed for #{client_info}"
    end
  end
end

# Start the proxy
if __FILE__ == $0
  options = {
    local_port: 3000,
    remote_port: 30000,
    remote_host: 'localhost'
  }

  OptionParser.new do |opts|
    opts.banner = "Usage: tcp_proxy.rb [options]"
    opts.separator ""
    opts.separator "Options:"

    opts.on("-l", "--local-port PORT", Integer, "Local port to listen on (default: 3000)") do |port|
      options[:local_port] = port
    end

    opts.on("-r", "--remote-port PORT", Integer, "Remote port to forward to (default: 30000)") do |port|
      options[:remote_port] = port
    end

    opts.on("-h", "--remote-host HOST", "Remote host to forward to (default: localhost)") do |host|
      options[:remote_host] = host
    end

    opts.on("--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!

  proxy = TCPProxy.new(
    local_port: options[:local_port],
    remote_port: options[:remote_port],
    remote_host: options[:remote_host]
  )
  proxy.start
end
