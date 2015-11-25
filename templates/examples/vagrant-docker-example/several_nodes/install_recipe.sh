#!/bin/bash

function error
{
    echo -e "\033[1;31m${1}\033[0m" 1>&2
}

function checkRequireRootUser
{
    if [[ "$(whoami)" != 'root' ]]
    then
        error "ERROR: please run this program as 'root'"
        exit 1
    fi
}

function installChef()
{
    if [[ "$(which chef-solo)" = '' ]]
    then
        local chefProfilePath='/etc/profile.d/chef.sh'

        curl -s -L 'https://www.opscode.com/chef/install.sh' | bash && \
        echo 'export PATH="/opt/chef/bin:/opt/chef/embedded/bin:$PATH"' > "${chefProfilePath}" && \
        source "${chefProfilePath}"
    fi
}

function installRecipe()
{
    /opt/chef/bin/chef-solo -c /vagrant/solo.rb -j /vagrant/solo.json
    /opt/chef/bin/chef-solo -c /vagrant/solo.rb --override-runlist "role["/vagrant/docker1"],recipe["mariadb::install_community"]"
}

function main()
{
    checkRequireRootUser
    installChef
    installRecipe
}

main
