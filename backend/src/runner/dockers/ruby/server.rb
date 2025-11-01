require 'sinatra'
require 'json'
require 'tempfile'

set :port, 5005
set :bind, '0.0.0.0'

before do
  headers 'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Methods' => ['POST', 'OPTIONS'],
          'Access-Control-Allow-Headers' => 'Content-Type'
end

options '*' do
  200
end

get '/health' do
  content_type :json
  { status: 'Ruby runner is running' }.to_json
end

post '/execute' do
  content_type :json

  begin
    data = JSON.parse(request.body.read)
    code = data['code'] || ''

    temp_file = Tempfile.new(['ruby_', '.rb'])
    temp_file.write(code)
    temp_file.close

    output = `ruby #{temp_file.path} 2>&1`

    {
      output: output.strip,
      success: $?.success?
    }.to_json

  rescue JSON::ParserError => e
    { output: "JSON parse error: #{e.message}" }.to_json
  rescue => e
    { output: "Error: #{e.message}" }.to_json
  ensure
    temp_file.unlink if temp_file
  end
end