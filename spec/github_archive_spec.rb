require 'spec_helper'

describe GithubArchiver do

  events = "CommitCommentEvent,CreateEvent,DeleteEvent,DeploymentEvent,DeploymentStatusEvent,DownloadEvent,ForkEvent,ForkApplyEvent,GollumEvent,IssueCommentEvent,IssuesEvent,MemberEvent,PageBuildEvent,PublicEvent,PullRequestEvent,PullRequestReviewCommentEvent,PushEvent,ReleaseEvent,StatusEvent,TeamAddEvent,WatchEvent".split ','

  describe 'Handles Invalid Parameters' do
    it "handles empty parameter" do
      expect {GithubArchiver.new([])}.to raise_error(InvalidInput, "Parameters must be key/value pairs")
    end

    it "handles odd number of parameter" do
      expect {GithubArchiver.new("--after 2012-11-01T13:00:00Z --before 2012-11-02T03:12:14-03:00 --event --count 42".split ' ')}.to raise_error(InvalidInput, "Parameters must be key/value pairs")
    end

    it "handles unknown parameter" do
      expect {GithubArchiver.new("--after 2012-11-01T13:00:00Z --before 2012-11-02T03:12:14-03:00 --cowbells PushEvent --count 42".split ' ')}.to raise_error(InvalidInput, "Unknown Parameter: --cowbells")
    end

    it "handles missing parameter" do
      expect {GithubArchiver.new("--after 2012-11-01T13:00:00Z --before 2012-11-02T03:12:14-03:00 --count 42".split ' ')}.to raise_error(InvalidInput, "Missing parameter: --event")
    end
  end

  describe 'Handles case listed in challenge problem' do
    it "returns expected number of records" do
      gh = GithubArchiver.new("--after 2012-11-01T13:00:00Z --before 2012-11-02T03:12:14-03:00 --event PushEvent --count 42".split ' ')
      results = gh.execute
      expect(results.length).to eq(42)
      puts results
    end
  end
end
