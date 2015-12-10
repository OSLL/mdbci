require 'rspec'
require 'spec_helper'
require_relative '../core/session'
require_relative '../core/repo_manager'

describe 'RepoManager' do

  context '.repos' do


    it "Check repos loading..." do

      path = './repo.d'
      repo = RepoManager.new(path)

      repo.repos.size().should_not eq(0)
      boxes.size().should eq(32)

    end

  end



end