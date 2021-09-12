require 'sinatra'
require 'lyon'

post '/payload' do
  push = LYON.parse(request.body.read)
  puts "I got some LYON: #{push.inspect}"
end 
