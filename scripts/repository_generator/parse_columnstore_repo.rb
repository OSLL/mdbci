#!/usr/bin/env ruby

require 'open-uri'
require 'nokogiri'
require 'pp'
require 'tmpdir'
require 'json'
require 'fileutils'

# The class is one-shot entity that is able to
class ColumnstoreRepoParser
  attr_reader :directory
  REPO_PAGE = 'https://downloads.mariadb.com/ColumnStore/'
  DEBIAN_REPO_KEY = 'AD0DEAFDA41F5C14'
  RHEL_REPO_KEY = "#{REPO_PAGE}MariaDB-ColumnStore.gpg.key"

  def initialize
    @directory = Dir.mktmpdir
    puts "Creating configuration in #{@directory}"
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

  # Get links on the specified page
  def get_links(path = '/')
    uri = "#{REPO_PAGE}/#{path}"
    doc = Nokogiri::HTML(open(uri))
    doc.css('#main a')
  end

  # Create repository for debian-based distribive
  # @param release [String] name of the release
  # @param system [String] name of the repository
  def create_debian_repo(release, system)
    repos = find_repos(release, 'repo', system).each_with_object([]) do |link, repositories|
      repo_link = "#{release}/repo/#{link[:href]}".gsub(/\/\//, '/')
      get_links("#{repo_link}/dists").each do |release_link|
        release_name = release_link.content.delete('/')
        repositories << {
          repo: "#{REPO_PAGE}#{repo_link} #{release_name} main",
          repo_key: DEBIAN_REPO_KEY,
          platform_version: release_name,
          platform: system,
          product: 'columnstore',
          version: release,
        }
      end
    end
    FileUtils.mkdir_p("#{@directory}/#{system}/")
    File.write("#{directory}/#{system}/#{release}.json", JSON.pretty_generate(repos))
  end

  def create_rhel_repo(release, system)
    repos = find_repos(release, 'yum', system).each_with_object([]) do |link, repositories|
      repo_link = "#{release}/yum/#{link[:href]}".gsub(/\/\//, '/')
      get_links("#{repo_link}").each do |release_link|
        release_name = release_link.content.delete('/')
        repositories << {
          repo: "#{REPO_PAGE}#{repo_link}/#{release_name}/x86_64",
          repo_key: RHEL_REPO_KEY,
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

  # Finds repositories by the type
  def find_repos(release, type, system)
    get_links("#{release}/#{type}").select do |link|
      link.content.include?(system)
    end
  end

  def parse
    find_vaiable_releases.each do |release|
      puts "Configuring release #{release}"
      create_rhel_repo(release, 'centos')
#      create_debian_repo(release, 'debian')
#      create_debian_repo(release, 'ubuntu')
    end
  end
end

ColumnstoreRepoParser.new.parse if $0 == __FILE__
