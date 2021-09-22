#!
require 'sinatra'
require 'json'

post 'altserver/payload' do
  push = JSON.parse(request.body.read)
  puts "I got some JSON: #{push.inspect}"
end
