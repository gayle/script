# you could use the sendmail command if you have that installed, or you could probably connect to the Outlook server
# or you could use notify-send to just popup an alert
require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'csv'

FOODS_I_WANT = [/PUMPKIN COCONUT BISQUE/i, /NACHO/i, /WURST.*BIER/i]
north_cafe = HTTParty.get("http://www.aramarkcafe.com/layouts/canary_2015/locationhome.aspx?locationid=4261&pageid=20&stationID=-1")
south_cafe = HTTParty.get("http://www.aramarkcafe.com/layouts/canary_2015/locationhome.aspx?locationid=4265&pageid=20&stationID=-1")

north_data = Nokogiri::HTML(north_cafe)
south_data = Nokogiri::HTML(south_cafe)

north_mon = north_data.css("#mondayColumn").text
north_tue = north_data.css("#tuesdayColumn").text
north_wed = north_data.css("#wednesdayColumn").text
north_thu = north_data.css("#thursdayColumn").text
north_fri = north_data.css("#fridayColumn").text

south_mon = south_data.css("#mondayColumn").text
south_tue = south_data.css("#tuesdayColumn").text
south_wed = south_data.css("#wednesdayColumn").text
south_thu = south_data.css("#thursdayColumn").text
south_fri = south_data.css("#fridayColumn").text


FOODS_I_WANT.each do |food|
  puts "Mon, NORTH has #{food}" if north_mon.match food
  puts "Tue, NORTH has #{food}" if north_tue.match food
  puts "Wed, NORTH has #{food}" if north_wed.match food
  puts "Thu, NORTH has #{food}" if north_thu.match food
  puts "Fri, NORTH has #{food}" if north_fri.match food

  puts "Mon, SOUTH has #{food}" if south_mon.match food
  puts "Tue, SOUTH has #{food}" if south_tue.match food
  puts "Wed, SOUTH has #{food}" if south_wed.match food
  puts "Thu, SOUTH has #{food}" if south_thu.match food
  puts "Fri, SOUTH has #{food}" if south_fri.match food
end
