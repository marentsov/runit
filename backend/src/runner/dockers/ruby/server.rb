require 'socket'
require 'json'
require 'tempfile'
require 'stringio'

class RubyRunnerServer
  def initialize(port = 5000)
    @port = port
    @server = TCPServer.new('0.0.0.0', port)
  end

  def start
    puts "✅ Ruby runner started on port #{@port}"
    puts "📍 Health check: http://0.0.0.0:#{@port}/health"

    loop do
      client = @server.accept
      Thread.new(client, &method(:handle_client))
    end
  end

  private

  def handle_client(client)
    request_line = client.gets
    return unless request_line

    method, path, _ = request_line.split
    headers = read_headers(client)
    body = read_body(client, headers)

    response = process_request(method, path, headers, body)

    send_response(client, response)
  ensure
    client.close
  end

  def read_headers(client)
    headers = {}
    while (line = client.gets)
      break if line.strip.empty?
      key, value = line.split(':', 2)
      headers[key.strip.downcase] = value.strip if key && value
    end
    headers
  end

  def read_body(client, headers)
    content_length = headers['content-length']&.to_i
    return '' unless content_length && content_length > 0

    client.read(content_length)
  end

  def process_request(method, path, headers, body)
    cors_headers = {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers' => 'Content-Type'
    }

    # Handle OPTIONS preflight
    if method == 'OPTIONS'
      return [200, cors_headers.merge('Content-Type' => 'application/json'), '']
    end

    case path
    when '/health', '/'
      response_data = { status: 'Ruby runner is running', timestamp: Time.now.to_i }
      [200, cors_headers.merge('Content-Type' => 'application/json'), response_data.to_json]

    when '/execute'
      if method == 'POST'
        handle_execute(body, cors_headers)
      else
        [405, cors_headers.merge('Content-Type' => 'application/json'), { error: 'Method not allowed' }.to_json]
      end

    else
      [404, cors_headers.merge('Content-Type' => 'application/json'), { error: 'Not found' }.to_json]
    end
  end

  def handle_execute(body, cors_headers)
    begin
      data = JSON.parse(body)
      code = data['code'] || ''

      temp_file = Tempfile.new(['ruby_', '.rb'])
      temp_file.write(code)
      temp_file.close

      output = `ruby #{temp_file.path} 2>&1`
      success = $?.success?

      response_data = {
        output: output.strip,
        success: success,
        exit_code: $?.exitstatus
      }

      [200, cors_headers.merge('Content-Type' => 'application/json'), response_data.to_json]

    rescue JSON::ParserError => e
      [400, cors_headers.merge('Content-Type' => 'application/json'), { output: "JSON error: #{e.message}" }.to_json]
    rescue => e
      [500, cors_headers.merge('Content-Type' => 'application/json'), { output: "Error: #{e.message}" }.to_json]
    ensure
      temp_file.unlink if temp_file
    end
  end

  def send_response(client, response)
    status, headers, body = response

    status_line = "HTTP/1.1 #{status} #{status_message(status)}\r\n"
    header_lines = headers.map { |k, v| "#{k}: #{v}\r\n" }.join
    content_length = "Content-Length: #{body.bytesize}\r\n" unless body.empty?

    client.write(status_line)
    client.write(header_lines)
    client.write(content_length) if content_length
    client.write("\r\n")
    client.write(body) unless body.empty?
  end

  def status_message(code)
    {
      200 => 'OK',
      400 => 'Bad Request',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      500 => 'Internal Server Error'
    }[code] || 'Unknown'
  end
end

# Start the server
server = RubyRunnerServer.new(5000)
server.start