# ===================================
# USAGE:
# find_pr_containing_commit.rb # you will be prompted for repo and commit hash
# find_pr_containing_commit.rb <repo> <commit_hash>
# repo = rsam|self_service|rsam_core, etc
#
# ===================================

require 'json'
require 'net/http'
require 'pry'

# ===================================
# CONSTANTS
# ===================================
BASE_URL = 'https://stash-prod2.us.jpmchase.net:8443/rest/api/1.0/projects/RSAM/repos'
NUM_RESULTS_AT_A_TIME = 10

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
# ARGS
# ===================================
if ARGV.length == 2
  @repo = ARGV[0]
  @commit = ARGV[1]
else
  print "which repo do you want to look in? "
  @repo = gets.chomp
  print "which commit hash are you looking for? "
  @commit = gets.chomp
end

# ===================================
# HELPERS
# ===================================

def call_stash_api(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  req = Net::HTTP::Get.new(uri.request_uri, {'Content-Type' => 'application/json', })
  req.basic_auth USERNAME, PASSWORD

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")
  response = http.request(req)
  JSON.parse(response.body)
end

def get_prs(start)
  url = "#{BASE_URL}/#{@repo}/pull-requests"
  params = {'state' => 'MERGED', 'order' => 'NEWEST', 'limit' => NUM_RESULTS_AT_A_TIME, 'start' =>  start}
  call_stash_api(url, params)
end

def get_commits_in_pr(pr_id)
  url = "#{BASE_URL}/#{@repo}/pull-requests/#{pr_id}/commits"
  params = {}
  commits = call_stash_api(url, params)
  commits["values"]
end

def pr_containing_commit(pull_requests, commit_hash)
  pull_requests.each do |pr|
    commits = get_commits_in_pr(pr["id"])
    commits_containing_hash = commits.select{|c| c["id"] == commit_hash}
    return pr if commits_containing_hash.first # .first will be nil if array is empty
  end
end

# ===================================
# RUN
# ===================================

# This doesn't work.  For some reason the gets tries to use the first command line arg.
# e.g. `gets': No such file or directory - rsam
# begin
#   json_response = get_prs
#   # do stuff
#   print "commit not found yet.  Continue? (y/n) " # if not_found
#   binding.pry
#   keep_going = gets.chomp
# end until keep_going != "y"


# Note in Ruby 2 you can use: "1.step(NUM_RESULTS_AT_A_TIME) do |i|" because infinity is the default
0.step(Float::INFINITY, NUM_RESULTS_AT_A_TIME) do |f|
  pull_requests = get_prs(f.to_i)

  # TODO print the created at date, so a person can CtrlC whenever they want

  if pull_requests["errors"]
    puts "ERRORS: #{pull_requests.inspect}"
    break
  end
  # binding.pry
  @pr = pr_containing_commit(pull_requests["values"], @commit)
  break if ((pull_requests["size"] == 0) or @pr)
end

if @pr.nil?
  puts "commit '#{@commit}' not found in any pr"
else
  puts "commit '#{@commit}' was found in '#{@repo}' pull request ##{@pr["id"]}"
end


# ===================================
# RESPONSE
# ===================================
#puts "Response: #{pull_requests}..."


