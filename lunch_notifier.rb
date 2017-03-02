# you could use the sendmail command if you have that installed, or you could probably connect to the Outlook server
# or you could use notify-send to just popup an alert
require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'csv'

south_cafe = HTTParty.get("http://www.aramarkcafe.com/layouts/canary_2015/locationhome.aspx?locationid=4265&pageid=20&stationID=-1")
north_cafe = HTTParty.get("http://www.aramarkcafe.com/layouts/canary_2015/locationhome.aspx?locationid=4261&pageid=20&stationID=-1")

north_data = Nokogiri::HTML(north_cafe)
north_mon = north_data.css("#mondayColumn").text
north_tue = north_data.css("#tuesdayColumn").text
north_wed = north_data.css("#wednesdayColumn").text
north_thu = north_data.css("#thursdayColumn").text
north_fri = north_data.css("#fridayColumn").text

puts "MON WOOT" if north_mon.match /pumpkin/i
puts "TUE WOOT" if north_tue.match /pumpkin/i
puts "WED WOOT" if north_wed.match /pumpkin/i
puts "THU WOOT" if north_thu.match /pumpkin/i
puts "FRI WOOT" if north_fri.match /pumpkin/i


