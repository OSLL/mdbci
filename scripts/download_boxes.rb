#!/usr/bin/env ruby

require 'json'
require 'getoptlong'
require 'net/http'
#require 'progressbar'
require 'fileutils'

PROVIDER = 'provider'
PLATFORM = 'platform'
PLATFORM_VERSION = 'platform_version'
BOX = 'box'
BOX_VERSION = 'box_version'

opts = GetoptLong.new(
    [ '--dir', '-d', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--boxes-dir', '-b', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--force', '-f', GetoptLong::NO_ARGUMENT ],
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ]
)

dir = nil
boxes_dir = nil

force = false

opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
download_boxes OPTION

-d, --dir:
  directory name where to store boxes

-b, --boxes-dir:
  directory name where to find JSON files with
  with boxes information

-h, --help:
  show help

-f, --force
  if directories already exists - they will be overwritten
      EOF
    when '--force'
      force = true
    when '--dir'
      dir = arg
    when '--boxes-dir'
      boxes_dir = arg
  end
end

puts dir
puts boxes_dir

# get BOXES/*.json
boxes = Hash.new
boxes_files = Dir.glob(boxes_dir.to_s + '/' + '*.json', File::FNM_DOTMATCH)
boxes_files.each do |boxes_file|
  puts "Box file: "+boxes_file.to_s
  next if boxes_file.to_s.include? 'aws'
  next if boxes_file.to_s.include? 'mdbci'
  next if boxes_file.to_s.include? 'docker'
  boxes_json = JSON.parse(File.read boxes_file)
  puts boxes_json
  boxes = boxes.merge boxes_json
end

boxes_quantity = boxes.length
puts boxes_quantity

boxes_paths = Array.new

boxes_counter = 0
box_atlas_url = ''
boxes.each do |box|
  box_name = box[1][BOX].to_s
  box_version = box[1][BOX_VERSION].to_s
  provider = box[1][PROVIDER].to_s

  if box_name =~ /\A#{URI::regexp(['http', 'https'])}\z/
    box_atlas_url = box_name
  else
    box_name = box[1][BOX].to_s.split('/')
    box_atlas_url = "https://atlas.hashicorp.com/#{box_name[0]}/boxes/#{box_name[1]}/versions/#{box_version}/providers/#{provider}.box"
  end

  if box_atlas_url =~ /\A#{URI::regexp(['http', 'https'])}\z/
    boxes_counter += 1
    puts "INFO: #{boxes_counter}/#{boxes_quantity}, downloading from url: '#{box_atlas_url}'"

    url_base = box_atlas_url.split('/')[2]
    url_path = '/'+box_atlas_url.split('/')[3..-1].join('/')

    platform = box[1][PLATFORM]
    platform_version = box[1][PLATFORM_VERSION]
    box_file_name = url_path.split('/')[-1]

    downloaded_box_dir = File.absolute_path([dir, provider, platform, platform_version, box_version].join('/'))
    downloaded_box_path = File.absolute_path([downloaded_box_dir, box_file_name].join('/'))
    boxes_paths.push downloaded_box_path

    puts "INFO: Box will be stored in '#{downloaded_box_path}'"

    if Dir.exists?(downloaded_box_dir) && File.exists?(downloaded_box_path)
      if !force
        at_exit { puts "ERROR: file '#{downloaded_box_path}' already exists" }
        exit 1
      else
        puts "WARNING: file '#{downloaded_box_path} will be overwritten"
        File.delete downloaded_box_path
      end
    end

    unless Dir.exists?(downloaded_box_dir)
      FileUtils.mkpath downloaded_box_dir
    end

    # download boxes by curl
    get_redirect_url_cmd = 'curl '+box_atlas_url
    redirect_vagrant_out = `#{get_redirect_url_cmd}`
    box_redirect_url = redirect_vagrant_out.split(/"(.*?)"/)[1]
    download_box_url_cmd = 'curl '+box_redirect_url+' > '+downloaded_box_path
    download_vagrant_out = `#{download_box_url_cmd}`
    puts download_vagrant_out

    puts "INFO: Box loaded successefully"
  else
    puts "INFO: Box will not be loaded - url #{box_atlas_url} is wrong"
  end
end
puts "INFO: Boxes loaded #{boxes_counter}/#{boxes_quantity}"

boxes_paths_file = File.absolute_path([dir, "boxes_paths"].join('/'))

if Dir.exists?(dir) && File.exists?(boxes_paths_file )
  if !force
    at_exit { puts "ERROR: file '#{boxes_paths_file }' already exists" }
    exit 1
  else
    puts "WARNING: file '#{boxes_paths_file}' will be overwritten"
    File.delete boxes_paths_file
  end
end

File.open(boxes_paths_file, 'w') do |f|
  boxes_paths.each do |path|
    f.puts path
  end
end

puts "INFO: File with boxes paths is stored as '#{boxes_paths_file}'"
