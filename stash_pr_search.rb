# ===================================
# USAGE:
# ruby stash_pr_search.rb # you will be prompted for information
# ruby stash_pr_search.rb <repo> <comment|commit> <value>
# repo = rsam|self_service|rsam_core, etc
#
# EXAMPLES:
# ruby stash_pr_search.rb rsam comment 'this is what I had to say'
# ruby stash_pr_search.rb keon-api commit 545dab7e4ef099ccb2c469eb0f148b16d3e8abff
# ruby stash_pr_search.rb self_service commit ef0c9ebd3f
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
if ARGV.length == 3
  @repo = ARGV[0]
  @search_type = ARGV[1]
  @value = ARGV[2]
else
  print "which repo do you want to look in? "
  @repo = gets.chomp

  print "what do you want to search for (commit|comment)? "
  @search_type = gets.chomp

  print "what value are you looking for? "
  @value = gets.chomp
end

if !["commit", "comment"].include? @search_type
  puts "unknown search type '#{@search_type}'"
  exit
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
  json_response = JSON.parse(response.body)

  if json_response["errors"]
    puts "ERRORS: #{json_response.inspect}"
    exit
  end
  json_response
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
    puts "checking PR ##{pr["id"]} created on #{Time.at pr["createdDate"]/1000}"
    commits = get_commits_in_pr(pr["id"])
    commits_containing_hash = commits.select{|c| c["id"].start_with? commit_hash}
    return pr if commits_containing_hash.first # .first will be nil if array is empty
  end
  nil
end

def get_comments_in_pr(pr_id)
  url = "#{BASE_URL}/#{@repo}/pull-requests/#{pr_id}/activities"
  params = {}
  activities = call_stash_api(url, params)
  comment_activities = activities["values"].select{|a| a["action"] == "COMMENTED"}
  comment_activities.collect{|c| c["comment"]["text"]}
end


def pr_containing_comment(pull_requests, comment_text)
  pull_requests.each do |pr|
    puts "checking PR ##{pr["id"]} created on #{Time.at pr["createdDate"]/1000}"
    comments = get_comments_in_pr(pr["id"])
    #binding.pry if pr["id"] == 25
    return pr if comments.any?{|c| c.include? comment_text}
    # TODO do I really want to just find the FIRST one, or returna  list of ones?
  end
  nil
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

  if @search_type == "commit"
    @pr = pr_containing_commit(pull_requests["values"], @value)
  elsif @search_type == "comment"
    @pr = pr_containing_comment(pull_requests["values"], @value)
  end

  break if ((pull_requests["size"] == 0) or @pr)
end

if @pr.nil?
  puts "#{@search_type} '#{@value}' not found in any '#{@repo}' pull request"
else
  # https://stash-prod2.us.jpmchase.net:8443/projects/RSAM/repos/keon-api/pull-requests/25
  pr_url = "https://stash-prod2.us.jpmchase.net:8443/projects/RSAM/repos/#{@repo}/pull-requests/#{@pr["id"]}"
  puts "\n#{@search_type} '#{@value}' was found in '#{@repo}' pull request ##{@pr["id"]}\n#{pr_url}\n\n"
end


# ===================================
# RESPONSE
# ===================================
#puts "Response: #{pull_requests}..."

