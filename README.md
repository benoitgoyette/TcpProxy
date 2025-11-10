# TCP Proxy - Tunnel
Built by Claude Sonnet 4.5

A simple Ruby TCP proxy that forwards connections from port 3000 to port 30000.

## Features

- Bidirectional TCP connection forwarding
- Multi-threaded to handle multiple concurrent connections
- Logging for connection tracking and debugging
- Graceful shutdown with Ctrl+C

## Requirements

- Ruby (2.5 or higher recommended)
- No external dependencies (uses only Ruby standard library)

## Usage

### Basic Usage

Run the proxy with default settings (port 3000 → localhost:30000):

   ```bash
   ruby tcp_proxy.rb
   ```

Or make it executable and run directly:

   ```bash
   chmod +x tcp_proxy.rb
   ./tcp_proxy.rb
   ```

### Command-Line Options

The proxy supports the following command-line options:

- `-l PORT` or `--local-port PORT` - Set the local port to listen on (default: 3000)
- `-r PORT` or `--remote-port PORT` - Set the remote port to forward to (default: 30000)
- `-h HOST` or `--remote-host HOST` - Set the remote host to forward to (default: localhost)
- `--help` - Show help message

### Examples

Forward port 8080 to localhost:9090:
   ```bash
   ruby tcp_proxy.rb -l 8080 -r 9090
   ```

Forward port 3000 to a remote server:
   ```bash
   ruby tcp_proxy.rb -l 3000 -r 80 -h example.com
   ```

Forward to a specific IP address:
```bash
   ruby tcp_proxy.rb -l 5000 -r 5432 -h 192.168.1.100
  ```

## How It Works

1. The proxy listens on port 3000
2. When a client connects, it opens a connection to port 30000
3. Data is forwarded bidirectionally between the client and the remote server
4. Each client connection is handled in a separate thread
5. Connections are properly closed when either side disconnects

## Testing

To test the proxy, you'll need:
1. A service running on port 30000
2. A client connecting to port 3000

Example test with netcat:

**Terminal 1** - Start a test server on port 30000:
   ```bash
   nc -l 30000
   ```

**Terminal 2** - Start the proxy:
   ```bash
   ruby tcp_proxy.rb
   ```

**Terminal 3** - Connect a client to port 3000:
   ```bash   
   nc localhost 3000
   ```

Now anything you type in Terminal 3 will appear in Terminal 1, and vice versa.

## Stopping the Proxy

Press `Ctrl+C` to gracefully stop the proxy.

## Troubleshooting

- **Port already in use**: Make sure port 3000 isn't being used by another application
- **Connection refused**: Ensure there's a service running on port 30000 before connecting clients
- **Permission denied**: On some systems, you may need elevated privileges to bind to ports below 1024

## License

MIT
