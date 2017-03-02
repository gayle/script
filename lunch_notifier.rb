# you could use the sendmail command if you have that installed, or you could probably connect to the Outlook server
# or you could use notify-send to just popup an alert
require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'csv'

FOODS_I_WANT = ["PUMPKIN COCONUT BISQUE", "NACHO"]
south_cafe = HTTParty.get("http://www.aramarkcafe.com/layouts/canary_2015/locationhome.aspx?locationid=4265&pageid=20&stationID=-1")
north_cafe = HTTParty.get("http://www.aramarkcafe.com/layouts/canary_2015/locationhome.aspx?locationid=4261&pageid=20&stationID=-1")

north_data = Nokogiri::HTML(north_cafe)
north_mon = north_data.css("#mondayColumn").text
north_tue = north_data.css("#tuesdayColumn").text
north_wed = north_data.css("#wednesdayColumn").text
north_thu = north_data.css("#thursdayColumn").text
north_fri = north_data.css("#fridayColumn").text


FOODS_I_WANT.each do |food|
  puts "Mon, NORTH has #{food}" if north_mon.match /#{food}/i
  puts "Tue, NORTH has #{food}" if north_tue.match /#{food}/i
  puts "Wed, NORTH has #{food}" if north_wed.match /#{food}/i
  puts "Thu, NORTH has #{food}" if north_thu.match /#{food}/i
  puts "Fri, NORTH has #{food}" if north_fri.match /#{food}/i
end
