require 'rubygems'
require 'bundler/setup'
require 'launchpad'
require 'json'
require 'httpi'

URL = ARGV[0] || "http://hudson.dyndns-office.com:8080/api/json"
all_jobs = {}
interaction = Launchpad::Interaction.new

interaction.response_to(:grid, :down) do |interaction, action|
  if job = all_jobs[{:x => action[:x], :y => action[:y]}]
    puts "found!"
    begin
      system "open '#{job}'"
    rescue => e
      puts e
    end
  else
    puts all_jobs[{:x => action[:x], :y => action[:y]}].inspect
  end
end

int_thread = Thread.new do |t|
  interaction.start
end

loop do
  request = HTTPI.get(URL)
  jobs = JSON.parse(request.body)['jobs']
  jobs.each_with_index do |job, i|
    x = i % 8
    y = i / 8
    all_jobs[{:x => x, :y => y}] = job['url']
    if job['color'] == 'blue'
      interaction.device.change(:grid, :x => i % 8, :y => i/8, :red => :off, :green => :high)
    elsif job['color'] == 'red'
      interaction.device.change(:grid, :x => i % 8, :y => i/8, :red => :high, :green => :off)
    else
      interaction.device.change(:grid, :x => i % 8, :y => i/8, :red => :low, :green => :low)
    end    
  end
  Thread.pass
  sleep 5
end

int_thread.join