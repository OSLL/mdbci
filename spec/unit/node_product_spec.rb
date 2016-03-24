require 'rspec'
require_relative '../spec_helper'

require_relative '../../core/session'
require_relative '../../core/node_product'
require_relative '../../core/out'
require_relative '../../core/repo_manager'

describe 'NodeProduct' do

  before :all do
    $session = Session.new
    $session.isSilent = true
    $out = Out.new

    $session.repoDir = './repo.d'
    $session.repos = RepoManager.new($session.repoDir)
  end

  #
  it 'Load correct maxscale product repo' do

    product_name = 'maxscale'
    product_version = 'default'
    full_platform = 'ubuntu^trusty'

    # test maxscale ubuntu repo
    maxscale_repo = { "product"=>"maxscale", "version"=>"default",
                     "repo"=>"http://maxscale-jenkins.mariadb.com/ci-repository/develop/mariadb-maxscale//ubuntu trusty main",
                     "repo_key"=>"70E4618A8167EE24", "platform"=>"ubuntu", "platform_version"=>"trusty" }
    repo = NodeProduct.getProductRepo(product_name, product_version, full_platform)
    repo.should eq(maxscale_repo)
  end

  it 'Load wrong maxscale product repo' do

    product_name = 'maxscale'
    product_version = 'default'
    full_platform = 'ubuntu^trusty'

    # test maxscale ubuntu repo
    maxscale_repo = { "product"=>"maxscale", "version"=>"10.0",
                     "repo"=>"http://maxscale-jenkins.mariadb.com/ci-repository/develop/mariadb-maxscale//ubuntu trusty main",
                     "repo_key"=>"70E4618A8167EE24", "platform"=>"ubuntu", "platform_version"=>"trusty" }
    repo = NodeProduct.getProductRepo(product_name, product_version, full_platform)
    repo.should_not eq(maxscale_repo)
  end
  #
  #
  it 'Load correct mariadb product repo' do

    product_name = 'mariadb'
    product_version = '10.0'
    full_platform = 'centos^7'

    # test mariadb centos7 repo
    mariadb_repo = { "product"=>"mariadb",
                      "version"=>"10.0",
                      "repo"=>"http://yum.mariadb.org/10.0/centos7-amd64",
                      "repo_key"=>"https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
                      "platform"=>"centos",
                      "platform_version"=>7 }
    repo = NodeProduct.getProductRepo(product_name, product_version, full_platform)
    repo.should eq(mariadb_repo)
  end

  it 'Load wrong maxscale product repo' do

    product_name = 'mariadb'
    product_version = '5.5'
    full_platform = 'centos^6'

    # test mariadb centos7 repo
    mariadb_repo = { "product"=>"mariadb",
                     "version"=>"10.0",
                     "repo"=>"http://yum.mariadb.org/10.0/centos7-amd64",
                     "repo_key"=>"https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
                     "platform"=>"centos",
                     "platform_version"=>7 }
    repo = NodeProduct.getProductRepo(product_name, product_version, full_platform)
    repo.should_not eq(mariadb_repo)
  end
  #
  #
  it 'Load correct galera product repo' do

    product_name = 'galera'
    product_version = '10.0'
    full_platform = 'centos^6'

    # test mariadb centos6 repo
    galera_repo = { "product"=>"galera",
                     "version"=>"10.0",
                     "repo"=>"http://yum.mariadb.org/10.0/centos6-amd64",
                     "repo_key"=>"https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
                     "platform"=>"centos",
                     "platform_version"=>6 }
    repo = NodeProduct.getProductRepo(product_name, product_version, full_platform)
    repo.should eq(galera_repo)
  end

  it 'Load wrong galera product repo' do

    product_name = 'galera'
    product_version = '5.5'
    full_platform = 'centos^6'

    # test mariadb centos7 repo
    galera_repo = { "product"=>"galera",
                     "version"=>"10.0",
                     "repo"=>"http://yum.mariadb.org/10.0/centos7-amd64",
                     "repo_key"=>"https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
                     "platform"=>"centos",
                     "platform_version"=>7 }
    repo = NodeProduct.getProductRepo(product_name, product_version, full_platform)
    repo.should_not eq(galera_repo)
  end
  #
  #
  it 'Load correct mysql product repo' do

    product_name = 'mysql'
    product_version = '5.6'
    full_platform = 'debian^wheezy'

    # test mariadb centos6 repo
    mysql_repo = { "product"=>"mysql",
        "version"=>"5.6",
        "repo"=>"deb http://repo.mysql.com/apt/debian/ wheezy mysql-5.6",
        "repo_key"=>"http://repo.mysql.com/RPM-GPG-KEY-mysql",
        "platform"=>"debian",
        "platform_version"=>"wheezy"
    }
    repo = NodeProduct.getProductRepo(product_name, product_version, full_platform)
    repo.should eq(mysql_repo)
  end

  it 'Load wrong mysql product repo' do

    product_name = 'mysql'
    product_version = '5.5'
    full_platform = 'centos^6'

    # test mariadb centos7 repo
    mysql_repo = { "product"=>"mysql",
        "version"=>"5.5",
        "repo"=>"http://repo.mysql.com/yum/mysql-5.5-community/sles/12/x86_64",
        "repo_key"=>"http://repo.mysql.com/RPM-GPG-KEY-mysql",
        "platform"=>"sles",
        "platform_version"=>12
    }
    repo = NodeProduct.getProductRepo(product_name, product_version, full_platform)
    repo.should_not eq(mysql_repo)
  end

end