# you could use the sendmail command if you have that installed, or you could probably connect to the Outlook server
# or you could use notify-send to just popup an alert
require 'httparty'
require 'nokogiri'

DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday"]
FOODS_I_WANT = [/PUMPKIN COCONUT BISQUE/i, /NACHO/i, /WURST.*BIER/i, /BACON/i]
north_cafe = HTTParty.get("http://www.aramarkcafe.com/layouts/canary_2015/locationhome.aspx?locationid=4261&pageid=20&stationID=-1")
south_cafe = HTTParty.get("http://www.aramarkcafe.com/layouts/canary_2015/locationhome.aspx?locationid=4265&pageid=20&stationID=-1")

north_data = Nokogiri::HTML(north_cafe)
south_data = Nokogiri::HTML(south_cafe)

DAYS.each do |day|
  FOODS_I_WANT.each do |food|
    north_food = north_data.css("##{day}Column").text
    message = "#{day.capitalize}, NORTH has #{food.to_s.gsub("?i-mx:","")}"
    puts message if north_food.match food
    Kernel.system( "notify-send '#{message}'") if north_food.match food

    south_food = south_data.css("##{day}Column").text
    message = "#{day.capitalize}, SOUTH has #{food.to_s.gsub("?i-mx:","")}"
    puts message if south_food.match food
    Kernel.system( "notify-send '#{message}'") if south_food.match food
  end
end
