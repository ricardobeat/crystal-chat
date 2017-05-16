require "./chat/*"
require "markdown"
require "kemal"
require "redis"

redis = Redis.new
bus = Redis.new

# ## SET rooms
# Contains all existing room names

# ## HASH [room_name]
# Stores each rooms' data

get "/" do
  rooms = redis.smembers("rooms")
  <<-OUT
  <html>
  <body>
    <pre>Rooms: #{rooms}</pre>
    <form id="form">
      <input type="text" id="message" /> <button id="send">Send</button>
    </form>
    <pre id="chat"></pre>
    <script>
      const { chat, form, message } = document.all

      ws = new WebSocket('ws://' + location.host + '/socket')
      ws.onmessage = (m) => {
        chat.innerHTML += '<p>' + m.data + '</p>'
      }

      form.onsubmit = (e) => {
        e.preventDefault()
        ws.send(message.value)
        message.value = ''
      }
    </script>
  </body>
  </html
  OUT
end

get "/new/:name" do |req|
  name = req.params.url["name"]
  redis.sadd("rooms", name)
  "added #{name}"
end

get "/rooms/:name" do |req|
  name = req.params.url["name"]
  redis.sismember("rooms", name)
end

# SOCKETS

CLIENTS = [] of HTTP::WebSocket

ws "/socket" do |socket|
  CLIENTS << socket

  socket.on_close do
    CLIENTS.delete socket
  end

  socket.on_message do |message|
    redis.publish("messages", message)
  end
end

spawn do
  bus.subscribe("messages") do |on|
    on.message do |channel, message|
      puts "Message: #{message}"
      CLIENTS.each do |socket|
        socket.send(Markdown.to_html(message))
      end
    end
  end
end

Kemal.run
