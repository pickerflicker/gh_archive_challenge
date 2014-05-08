#require 'httparty'
require 'open-uri'
require 'pp'
require 'time'
require 'yajl'
require 'zlib'

class InvalidInput < StandardError
  def initialize(msg)
    super(msg)
  end
end

class UnknownEvent < StandardError
  def initialize(msg)
    super(msg)
  end
end

class GithubArchiver
  GH_ARCHIVE_URL = "http://data.githubarchive.org/"
  ALLOWED_PARAMS = ['--after', '--before', '--event', '--count']  # note there was a typo in problem statement, I'm using '--count' instead of '-n'

  def self.show_usage
    puts "USAGE: gh_repo_stats [--after DATETIME] [--before DATETIME] [--event EVENT_NAME] [-n COUNT]"
  end

  def initialize(input)
    @params = {}
    parse_input(input)
  end

  def parse_input(input)
    if input.nil? || input.empty? || input.size.odd?
      raise InvalidInput, "Parameters must be key/value pairs"
    end

    0.step(input.size-1, 2) do |k|
      name = input[k].downcase
      value = input[k+1]
      if ALLOWED_PARAMS.include? name
        @params[name] = value
      else
        raise InvalidInput, "Unknown Parameter: #{name}"
      end
    end

    # ensure that all parameters are set
    ALLOWED_PARAMS.each do |k|
      raise InvalidInput, "Missing parameter: #{k}" unless @params.has_key? k
    end
    @params["--event"] = @params["--event"].downcase
  end

  def parse_event(event)
    # based on emperical data, different events store the timestamp and repo name differently.  See "sample_data.txt"

    key = "#{event["repository"]["owner"]}/#{event["repository"]["name"]}"

    unless time = event["pushed_at"]
      time = event["created_at"]
    end

    return key, time
  rescue StandardError=>e
    puts "error: " + e.message
  end

  def execute
    # event data is stored hourly into gzip file
    start_time = Time.parse @params["--after"]
    end_time = Time.parse @params["--before"]

    # floor start_time and ceil end_time to ensure we download all the data possibly needed
    start_range = Time.utc(start_time.year, start_time.month, start_time.day, start_time.hour)
    hour_adjust = ((end_time.to_i%3600) == 0) ? 0 : 1
    end_range = Time.utc(end_time.year, end_time.month, end_time.day, end_time.hour+hour_adjust)

    results = Hash.new(0)

    (start_range.to_i..end_range.to_i).step(3600) do |hour_time|
      t = Time.at(hour_time).utc
      filename = "#{sprintf '%02d', t.year}-#{sprintf '%02d', t.month}-#{sprintf '%02d', t.day}-#{t.hour}.json.gz"

      puts " - Processing #{GH_ARCHIVE_URL + filename}..."
      gz = open(GH_ARCHIVE_URL + filename)
      js = Zlib::GzipReader.new(gz).read

      Yajl::Parser.parse(js) do |event|
        type = event["type"].downcase

        # look at each event type and see where the timestamp is coming from
        # FollowEvent, GistEvent event types don't have "repository" field, so these events are not counted towards repository activity
        unless type == "followevent" || type == "gistevent"
          key, time = parse_event(event)
          time = Time.parse time

          #filter by date range and event type
          results[key] += 1 if ( (time >= start_time) && (time <= end_time) && (@params["--event"]==type))
        end
      end
    end

    num_elems_to_drop = results.size - Integer(@params["--count"])
    num_elems_to_drop = 0 if num_elems_to_drop < 0

    Hash[results.sort_by{|k,v| v}.drop(num_elems_to_drop).reverse]
  end
end