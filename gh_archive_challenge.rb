require_relative 'github_archiver'

gh = GithubArchiver.new
begin
  gh.parse_input(ARGV)
rescue InvalidInput => e
  puts e.message
  puts gh.show_usage
  exit(1)
end