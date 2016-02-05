require 'json'
require 'net/http'

# ===================================
# ENV VARIABLES
# ===================================
USERNAME = ENV['USERNAME']
PASSWORD = ENV['PASSWORD']

if USERNAME.nil?
  puts "ENV variable USERNAME is nil"
  exit(0)
elsif PASSWORD.nil?
  puts "ENV variable PASSWORD is nil"
  exit(0)
end

# ===================================
# URL CONSTRUCTION
# TODO make some of these commmand line args
# ===================================
base_url = 'https://stash-prod2.us.jpmchase.net:8443/rest/api/1.0/projects/RSAM/repos'
repo = 'rsam' # The repo name in stash
type = 'pull-requests'
id = '2024'
URL = "#{base_url}/#{repo}/#{type}/#{id}"

# ===================================
# RUN
# ===================================
start = Time.now


uri = URI(URL)
req = Net::HTTP::Get.new(uri.request_uri)
req.basic_auth USERNAME, PASSWORD

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = (uri.scheme == "https")
response = http.request(req)

response.body
json_response = JSON.parse(response.body)


# ===================================
# RESPONSE
# ===================================
puts "[#{Time.now}] Response: #{json_response.inspect}..."
puts "Time: %0.1f secs" % [Time.now-start]

