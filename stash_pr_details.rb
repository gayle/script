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
  @pr_number = ARGV[1].to_i
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

def pr_url(repo, pr_id)
  "#{BASE_URL}/#{repo}/pull-requests/#{pr_id}"
end

def get_pr(id)
  url = pr_url(@repo, id)
  call_stash_api(url, {})
end

def display_date(date)
  Time.at date/1000
end

# ===================================
# ACTIVITY
# ===================================
def get_activities(pr_id)
  url = "#{BASE_URL}/#{@repo}/pull-requests/#{pr_id}/activities"
  params = {}
  activities = call_stash_api(url, params)
end

# [11] pry(main)> activities["values"].map{|v| v["action"]}
# => ["MERGED", "APPROVED", "APPROVED", "COMMENTED", "COMMENTED", "COMMENTED", "COMMENTED", "OPENED"]
def activities_by_types(pr_id, activity_types)
  activities = get_activities(pr_id)
  activities.empty? ? {} : activities["values"].select{|a| activity_types.include? a["action"]}
end


# ===================================
# RUN
# ===================================
  # TODO how to know when people are added to the PR
  pr = get_pr(@pr_number)
  puts pr_url(@repo, @pr_number)
  puts pr["title"]
  puts pr["description"]
  pr["author"]["user"]["displayName"]

  relevant_activities = activities_by_types(@pr_number, ["OPENED","APPROVED","COMMENTED","MERGED"])
  if (relevant_activities.size == 0)
    puts "Unable to find activities for pr '#{@pr_number}' in #{@repo} repo"
    exit(0)
  else
    ordered_activities = relevant_activities.sort_by{|a| a["createdDate"] }
    ordered_activities.each do |activity|
      puts "#{display_date(activity["createdDate"])} #{activity["action"]} by #{activity["user"]["displayName"]} "
    end
  end
