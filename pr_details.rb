# ===================================
# USAGE:
# ruby pr_details.rb # you will be prompted for information
# ruby pr_details.rb <repo> <pr number>
# repo = rsam|self_service|rsam_core, etc
#
# EXAMPLES:
# ruby pr_details.rb
# ruby pr_details.rb rsam 2354
# ===================================
# https://developer.atlassian.com/static/rest/stash/3.11.3/stash-rest.html

require 'json'
require 'net/http'
require 'pry'
require './pr_helpers'
include PrHelpers

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
