#!/usr/bin/ruby
require_relative 'github_archiver'

begin
gh = GithubArchiver.new(ARGV)
rescue InvalidInput => e
  puts e.message
  puts GithubArchiver.show_usage
  exit(1)
end
results = gh.execute
puts "\nResults\n------------------------"
results.each do |k,v|
  puts "#{k} - #{v} events"
end