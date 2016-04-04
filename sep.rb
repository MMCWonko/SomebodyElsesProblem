#!/usr/bin/env ruby

require 'fileutils'
begin; require 'pry'; rescue LoadError; end
require 'json'
require 'webrick'

###### Initial setup ######
$options = {
  outdir: ENV['SEP_OUTDIR'],
  port: ENV['SEP_PORT'] || 8022
}
if $options[:outdir].nil?
  puts 'You need to specify an output directory with -o!'
  exit
end

FileUtils.mkdir_p $options[:outdir] unless Dir.exists? $options[:outdir]

###### Various helpers ######
def wonkofile_filename(uid)
  $options[:outdir] + '/' + uid + '.json'
end
def wonkoversion_filename(uid, version)
  $options[:outdir] + '/' + uid + '/' + version + '.json'
end
def read_json_file(filename)
  JSON.parse File.read filename
end
def write_json_file(filename, json)
  File.write filename, JSON.pretty_generate(json)
end

###### Functions that actually do stuff ######
def wonkofile_merge(old, new)
  res = old.merge new
  # changing versions is not allowed by adding another version index (we might end up with a version in the index that
  # we don't have an actual version file for)
  res['versions'] = old['versions']
  res
end
def wonkofile_add_version(file, version)
  file['versions'] = [] if file['versions'].nil?

  existing_index = file['versions'].find_index { |v| v['version'] == version['version'] }

  # we only want some selected data for the index
  version = {
    version: version['version'],
    type: version['type'],
    time: version['time'],
    requires: version['requires']
  }

  if existing_index
    file['versions'][existing_index] = version
  else
    file['versions'] << version
  end
  file
end
def wonkofile_stub_from_wonkoversion(version)
  {
    'uid' => version['uid'],
    'versions' => [],
    'formatVersion' => 10
  }
end


###### Recognize if it's a version or version index, merge and write to disk
def handle_input(data)
  puts 'New file received'
  unless data.key? 'uid'
    puts 'File without UID found, skipping'
    return
  end

  wonkofile_fn = wonkofile_filename data['uid']
  version_filename = wonkoversion_filename data['uid'], data['version']

  if data.key? 'name'
    puts '  Found \'name\' key in received file, assuming WonkoFile'

    if File.exists? wonkofile_fn
      write_json_file wonkofile_fn, wonkofile_merge(read_json_file(wonkofile_fn), data)
    else
      write_json_file wonkofile_fn, data
    end
  else
    puts '  No \'name\' key found in received file, assuming WonkoVersion'

    # write the version
    FileUtils.mkdir_p File.dirname version_filename
    write_json_file version_filename, data

    # add the version to the version index
    wfile = File.exists?(wonkofile_fn) ? read_json_file(wonkofile_fn) : wonkofile_stub_from_wonkoversion(data)
    wfile = wonkofile_add_version wfile, data
    write_json_file wonkofile_fn, wfile
  end
end

###### Create and start the server ######
$server = WEBrick::HTTPServer.new Port: $options[:port], BindAddress: '127.0.0.1'
$server.mount_proc '/' do |req, res|
  data = req.query.key?('file') ? req.query['file'] : req.body
  handle_input data
  res.body = '<html><head><title>Success</title></head><body><h1>Successfully uploaded!</h1></body></html>'
end

puts 'Press Ctrl+C to quit...'
trap('INT') { $server.shutdown }
$server.start
