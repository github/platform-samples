basics-of-authentication
================

This is the sample projct built by following the "[Basics of Authentication][basics of auth]"
guide on developer.github.com.

It consists of two different servers: one built correctly, and one built less optimally.

To run these projects, make sure you have [Bundler][bundler] installed; then type
`bundle install` on the command line.

For the "less optimal" server, type `ruby server.rb` on the command line. 
This will run the server at `localhost:4567`.

For the correct server, enter `rackup -p 4567` on the command line.

[basics of auth]: http://developer.github.com/guides/basics-of-authentication/
[bundler]: http://gembundler.com/