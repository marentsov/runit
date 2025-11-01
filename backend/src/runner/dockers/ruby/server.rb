require 'webrick'
require 'json'
require 'tempfile'

# Создаем HTTP сервер
server = WEBrick::HTTPServer.new(Port: 5005, BindAddress: '0.0.0.0')

# Health check endpoint
server.mount_proc '/health' do |req, res|
  res['Content-Type'] = 'application/json'
  res['Access-Control-Allow-Origin'] = '*'
  res.body = {
    status: 'Ruby runner is running',
    timestamp: Time.now.to_i
  }.to_json
end

# Execute code endpoint
server.mount_proc '/execute' do |req, res|
  # CORS headers
  res['Content-Type'] = 'application/json'
  res['Access-Control-Allow-Origin'] = '*'
  res['Access-Control-Allow-Methods'] = 'POST, OPTIONS, GET'
  res['Access-Control-Allow-Headers'] = 'Content-Type'

  # Handle OPTIONS preflight
  if req.request_method == 'OPTIONS'
    res.status = 200
    res.body = ''
    next
  end

  # Handle POST request
  if req.request_method == 'POST'
    begin
      # Parse JSON body
      body = req.body
      data = JSON.parse(body)
      code = data['code'] || ''

      # Create temporary file with code
      temp_file = Tempfile.new(['ruby_', '.rb'])
      temp_file.write(code)
      temp_file.close

      # Execute Ruby code and capture output
      output = `ruby #{temp_file.path} 2>&1`
      success = $?.success?

      # Prepare response
      response = {
        output: output.strip,
        success: success,
        exit_code: $?.exitstatus
      }

      res.body = response.to_json

    rescue JSON::ParserError => e
      res.body = { output: "JSON parse error: #{e.message}" }.to_json
    rescue => e
      res.body = { output: "Error: #{e.message}" }.to_json
    ensure
      # Cleanup temp file
      temp_file.unlink if temp_file
    end
  else
    res.status = 405
    res.body = { error: 'Method not allowed' }.to_json
  end
end

# Root endpoint
server.mount_proc '/' do |req, res|
  res['Content-Type'] = 'application/json'
  res['Access-Control-Allow-Origin'] = '*'
  res.body = {
    message: 'Ruby Code Runner API',
    endpoints: {
      health: '/health',
      execute: '/execute'
    }
  }.to_json
end

# Graceful shutdown handlers
trap('INT') do
  puts "\nShutting down Ruby runner..."
  server.shutdown
end

trap('TERM') do
  puts "\nShutting down Ruby runner..."
  server.shutdown
end

puts "Ruby runner started on port 5005"
puts "📍 Health check: http://0.0.0.0:5005/health"
server.start