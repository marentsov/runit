require 'webrick'
require 'json'
require 'tempfile'

server = WEBrick::HTTPServer.new(Port: 5000)

server.mount_proc '/health' do |req, res|
  res['Content-Type'] = 'application/json'
  res['Access-Control-Allow-Origin'] = '*'
  res.body = { status: 'Ruby runner is running' }.to_json
end

server.mount_proc '/execute' do |req, res|
  res['Content-Type'] = 'application/json'
  res['Access-Control-Allow-Origin'] = '*'
  res['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
  res['Access-Control-Allow-Headers'] = 'Content-Type'

  if req.request_method == 'OPTIONS'
    res.status = 200
    next
  end

  begin
    data = JSON.parse(req.body)
    code = data['code'] || ''

    temp_file = Tempfile.new(['ruby_', '.rb'])
    temp_file.write(code)
    temp_file.close

    output = `ruby #{temp_file.path} 2>&1`

    res.body = { output: output.strip }.to_json
  rescue => e
    res.body = { output: "Error: #{e.message}" }.to_json
  ensure
    temp_file.unlink if temp_file
  end
end

trap('INT') { server.shutdown }
server.start