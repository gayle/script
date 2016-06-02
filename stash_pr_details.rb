# ===================================
# USAGE:
# ruby stash_pr_details.rb # you will be prompted for information
# ruby stash_pr_search.rb <repo> <pr number>
# repo = rsam|self_service|rsam_core, etc
#
# EXAMPLES:
# ruby stash_pr_search.rb
# ruby stash_pr_search.rb rsam 2354
# ===================================
# https://developer.atlassian.com/static/rest/stash/3.11.3/stash-rest.html

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
  @pr_number = ARGV[1]
else
  print "which repo do you want to look in? "
  @repo = gets.chomp

  print "which PR number do you want details for? "
  @pr_number = gets.chomp
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
  json_response = JSON.parse(response.body, :max_nesting => 100)

  if json_response["errors"]
    puts "ERRORS: #{json_response.inspect}"
    return {}
  end
  json_response
end

def pr_url(repo, pr)
  "https://stash-prod2.us.jpmchase.net:8443/projects/RSAM/repos/#{repo}/pull-requests/#{pr["id"]}"
end

def get_pr(id)
  url = "#{BASE_URL}/#{@repo}/pull-requests"
  params = {'pullRequestId' => id}
  call_stash_api(url, params)
end

def display_date(date)
  Time.at date/1000
end

# [11] pry(main)> activities["values"].map{|v| v["action"]}
# => ["MERGED", "APPROVED", "APPROVED", "COMMENTED", "COMMENTED", "COMMENTED", "COMMENTED", "OPENED"]
def activities_by_type(activities, activity_type)
  activities.empty? ? {} : activities["values"].select{|a| a["action"] == activity_type}
end

# ===================================
# ACTIVITY
# ===================================
def get_activities(pr_id)
  url = "#{BASE_URL}/#{@repo}/pull-requests/#{pr_id}/activities"
  params = {}
  activities = call_stash_api(url, params)
end

# ===================================
# COMMITS
# ===================================
def get_commits_in_pr(pr_id)
  url = "#{BASE_URL}/#{@repo}/pull-requests/#{pr_id}/commits"
  params = {}
  commits = call_stash_api(url, params)
  commits["values"]
end

def pr_containing_commit(pull_requests, commit_hash)
  found = nil
  pull_requests.each do |pr|
    print "\rchecking PR ##{pr["id"]} created on #{display_date(pr["createdDate"])}"
    commits = get_commits_in_pr(pr["id"])
    commits_containing_hash = commits.select{|c| c["id"].start_with? commit_hash}
    found = pr if commits_containing_hash.first # .first will be nil if array is empty
    break if found
  end

  if found
    url = pr_url(@repo, found)
    puts "\n#{@search_type} '#{@value}' was found in '#{@repo}' pull request ##{found["id"]}"
    puts "#{url}\n\n"
  end
  found
end


# ===================================
# TEXT
# ===================================
def get_comments_in_pr(pr_id)
  activities = get_activities(pr_id)
  comment_activities = activities_by_type(activities, "COMMENTED") # activities.empty? ? {} : activities["values"].select{|a| a["action"] == "COMMENTED"}
  comment_activities.collect{|c| c["comment"]["text"]}
end

def get_pr_text(pr_id)
  url = "#{BASE_URL}/#{@repo}/pull-requests/#{pr_id}"
  pr = call_stash_api(url, {})
  [pr["description"], pr["title"]].compact
end

def pr_containing_text(pull_requests, text)
  any_found = nil

  pull_requests.each do |pr|
    found = nil
    print "\rchecking PR ##{pr["id"]} created on #{display_date(pr["createdDate"])}"
    comments = get_comments_in_pr(pr["id"])
    other_text = get_pr_text(pr["id"])
    found = pr if (comments+other_text).any?{|c| c.include? text}
    if found
      any_found = pr
      url = pr_url(@repo, found)
      puts "\n#{@search_type} '#{@value}' was found in '#{@repo}' pull request ##{found["id"]}"
      puts "#{url}\n\n"
    end
  end

  any_found # will return nil if none were ever found
end


# ===================================
# RUN
# ===================================
  pull_requests = get_pr(f.to_i)

  if @search_type == "commit"
    @pr = pr_containing_commit(pull_requests["values"], @value)
  elsif @search_type == "text"
    @pr = pr_containing_text(pull_requests["values"], @value)
  end

  break if (pull_requests["size"] == 0)


puts "\n\n#{@search_type} '#{@value}' not found in any '#{@repo}' pull request" if @pr.nil?
