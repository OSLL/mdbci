#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'pp'
require 'tmpdir'
require 'json'
require 'fileutils'

# The class is one-shot entity that creates temporary directory and creates
# MDBCI repository configuration for all supported distributions.
class ColumnstoreRepoParser
  attr_reader :directory
  REPO_PAGE = 'https://downloads.mariadb.com/ColumnStore/'
  DEBIAN_REPO_KEY = 'AD0DEAFDA41F5C14'
  RHEL_REPO_KEY = "#{REPO_PAGE}MariaDB-ColumnStore.gpg.key"

  def initialize
    @directory = Dir.mktmpdir
    puts "Creating configuration in #{@directory}"
  end

  # Get links on the specified page
  def get_links(path = '/')
    uri = "#{REPO_PAGE}/#{path}"
    doc = Nokogiri::HTML(open(uri))
    doc.css('#main a')
  end

  # This method goes throug the main page and finds releases that sholud be added to
  # the repository
  def find_vaiable_releases
    get_links('/').select do |link|
      link.content =~ /\/$/
    end.select do |link|
      links = get_links(link[:href])
                .map { |sublink| sublink.content }
      links.include?('repo/') || link.include?('yum/')
    end.map(&:content).map do |text|
      text.delete('/')
    end
  end

  SYSTEMS = {
    debian: {
      path: 'repo',
      key: DEBIAN_REPO_KEY,
      release_path: -> (repo_link) { "#{repo_link}/dists" },
      repo_path: -> (repo_link, release_name) { "#{REPO_PAGE}#{repo_link} #{release_name} main" }
    },
    rhel: {
      path: 'yum',
      key: RHEL_REPO_KEY,
      release_path: -> (repo_link) { repo_link },
      repo_path: -> (repo_link, release_name) { "#{REPO_PAGE}#{repo_link}/#{release_name}/x86_64" }
    }
  }
  def create_repo(release, system, type)
    puts "Creating repository configuration for #{system} and columnstore #{release} release"
    system_type = SYSTEMS[type]
    subpath = system_type[:path]
    repos = get_links("#{release}/#{subpath}").select do |link|
      link.content.include?(system) && !link.content.include?('.')
    end.each_with_object([]) do |link, repositories|
      repo_link = "#{release}/#{subpath}/#{link[:href]}".gsub(/\/\//, '/')
      get_links(system_type[:release_path].call(repo_link)).each do |release_link|
        release_name = release_link.content.delete('/')
        repo_path = system_type[:repo_path].call(repo_link, release_name)
        repositories << {
          repo: repo_path,
          repo_key: system_type[:key],
          platform_version: release_name,
          platform: system,
          product: 'columnstore',
          version: release
        }
      end
    end
    FileUtils.mkdir_p("#{directory}/#{system}")
    File.write("#{directory}/#{system}/#{release}.json", JSON.pretty_generate(repos))
  end

  def parse
    find_vaiable_releases.each do |release|
      puts "Configuring release #{release}"
      create_repo(release, 'centos', :rhel)
      create_repo(release, 'sles', :rhel)
      create_repo(release, 'rhel', :rhel)
      create_repo(release, 'debian', :debian)
      create_repo(release, 'ubuntu', :debian)
    end
  end
end

ColumnstoreRepoParser.new.parse if $0 == __FILE__
