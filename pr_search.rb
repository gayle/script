# ===================================
# USAGE:
# ruby pr_search.rb # you will be prompted for information
# ruby pr_search.rb <repo> <text|commit|activity> <value>
# repo = rsam|self_service|rsam_core, etc
#
# EXAMPLES:
# ruby pr_search.rb rsam text 'this is what I had to say' # searches text in comments, description, title, etc.
# ruby pr_search.rb keon-api commit 545dab7e4ef099ccb2c469eb0f148b16d3e8abff
# ruby pr_search.rb self_service commit ef0c9ebd3f
# ruby pr_search.rb rsam activity 2161  # the value is the PR ID
# ===================================

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
if ARGV.length == 3
  @repo = ARGV[0]
  @search_type = ARGV[1]
  @value = ARGV[2]
else
  print "which repo do you want to look in? "
  @repo = gets.strip

  print "what do you want to search for (commit|text|activity)? "
  @search_type = gets.strip

  print "what value are you looking for? "
  @value = gets.strip
end

if !["commit", "text", "activity"].include? @search_type
  puts "unknown search type '#{@search_type}'"
  exit
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


if @search_type == "activity"
  opened_activity = activities_by_types(@value, ["OPENED"]).first
  if opened_activity
    puts "#{opened_activity["action"]} by #{opened_activity["user"]["displayName"]} at #{display_date(opened_activity["createdDate"])}"
  end

  merged_activity = activities_by_types(@value, ["MERGED"]).first
  if merged_activity
    puts "#{merged_activity["action"]} by #{merged_activity["user"]["displayName"]} at #{display_date(merged_activity["changeset"]["authorTimestamp"])}"
  end

  # TODO can add more activities here if we want to later

  exit(0)
end

# Note in Ruby 2 you can use: "1.step(NUM_RESULTS_AT_A_TIME) do |f|" because infinity is the default
0.step(Float::INFINITY, NUM_RESULTS_AT_A_TIME) do |f|
  pull_requests = get_prs(f.to_i)
  break if (pull_requests["size"] == 0)

  if @search_type == "commit"
    @pr = pr_containing_commit(pull_requests["values"], @value)
  elsif @search_type == "text"
    @pr = pr_containing_text(pull_requests["values"], @value)
  end

  break if !@pr.nil?
end

puts "\n\n#{@search_type} '#{@value}' not found in any '#{@repo}' pull request" if @pr.nil?
