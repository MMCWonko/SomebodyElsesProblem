#!/usr/bin/env ruby

require 'optparse'
require 'listen'
require 'fileutils'
require 'pry'
require 'json'
require 'webrick'

$options = {
  outdir: nil,
  indir: nil
}
OptionParser.new do |opts|
  opts.banner = "Usage: sep.rb -o OUTDIR -i INDIR"
  opts.on '-o', '--outdir OUTDIR', 'The directory root to where to output files' do |dir|
    $options[:outdir] = dir
  end
  opts.on '-i', '--indir INDIR', 'The directory to scan for new files' do |dir|
    $options[:indir] = dir
  end
  opts.on '--server PORT', 'Runs the backend upload server' do |port|
    $server = WEBrick::HTTPServer.new Port: port, BindAddress: '127.0.0.1'
    $server.mount_proc '/upload' do |req, res|
      binding.pry
      res.body = '<html><head><title>Success</title></head><body><h1>Successfully uploaded!</h1></body></html>'
    end
  end
end.parse!

if $options[:outdir].nil?
  puts 'You need to specify an output directory with -o!'
  exit
end
if $options[:indir].nil?
  puts 'You need to specify an input directory with -i!'
  exit
end

FileUtils.mkdir_p $options[:indir] unless Dir.exists? $options[:indir]
FileUtils.mkdir_p $options[:outdir] unless Dir.exists? $options[:outdir]

def wonkofile_filename(uid)
  $options[:outdir] + '/' + uid + '.json'
end
def wonkoversion_filename(uid, version)
  $options[:outdir] + '/' + uid + '/' + version + '.json'
end

def wonkofile_merge(old, new)
  res = old.merge new
  res['versions'] = old['versions']
  new['versions'].each do |ver|
    index = res['versions'].find_index { |v| v['version'] == ver['version'] }
    res['versions'] << ver if index.nil?
    res['versions'][index] = ver unless index.nil?
  end unless new['versions'].nil?
  res
end
def wonkofile_stub_from_wonkoversion(version)
  {
    'uid' => version['uid'],
    'versions' => [{
                version: version['version'],
                type: version['type'],
                time: version['time'],
                requires: version['requires']
              }]
  }
end

def read_json_file(filename)
  JSON.parse File.read filename
end
def write_json_file(filename, json)
  File.write filename, JSON.pretty_generate(json)
end

def handle_file(filename)
  return if File.directory? filename
  puts 'New file detected: ' + filename
  data = read_json_file filename
  if not data.key? 'uid'
    puts 'File without UID found, skipping'
    return
  end
  if data.key? 'name'
    puts '  Found \'name\' key in ' + filename + ', assuming WonkoFile'
    if File.exists? wonkofile_filename(data['uid'])
      write_json_file wonkofile_filename(data['uid']), wonkofile_merge(read_json_file(wonkofile_filename data['uid']), data)
    else
      write_json_file wonkofile_filename(data['uid']), data
    end
  else
    puts '  No \'name\' key found in ' + filename + ', assuming WonkoVersion'
    FileUtils.mkdir_p File.dirname wonkoversion_filename(data['uid'], data['version'])
    write_json_file wonkoversion_filename(data['uid'], data['version']), data
    if File.exists? wonkofile_filename(data['uid'])
      write_json_file wonkofile_filename(data['uid']), wonkofile_merge(read_json_file(wonkofile_filename data['uid']), wonkofile_stub_from_wonkoversion(data))
    else
      write_json_file wonkofile_filename(data['uid']), wonkofile_stub_from_wonkoversion(data)
    end
  end
  File.delete filename
end

Dir[$options[:indir] + '/**/*'].each { |file| handle_file file }

puts 'Setting up input dir listener...'
listener = Listen.to $options[:indir], only: /\.json$/ do |modified, added, removed|
  added.each do |file|
    handle_file file
  end
end.start

puts 'Listener successfully setup, operating normally'
puts 'Press Ctrl+C to quit...'
if $server.nil?
  sleep
else
  trap 'INT' { $server.shutdown }
  $server.start
end
listener.stop
