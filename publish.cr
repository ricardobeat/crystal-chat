require "redis"

redis = Redis.new
puts "Connected to Redis"
while true
  print "Please enter a message: "
  message = gets.not_nil!.strip
  redis.publish("messages", message)
  puts "Sent \"#{message}\" to mychannel"
  puts
end
