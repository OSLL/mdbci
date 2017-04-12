## Configuration files

MDBCI configuration is placed to the next files:

* boxes.json
* repo.d directory and repo.json files
* templates
* aws-config.yml

### boxes.json

The file boxes.json contains definitions of available boxes. His format is commented below (**NOTE** real json does not support comments, we used ## just for this documentation). 

```
{

  ## Example of VirtualBox definition
  "debian" : { ## Box name
    "provider": "virtualbox",
    "box": "https://atlas.hashicorp.com/.../virtualbox.box", ## Box URL
    "platform": "debian",
    "platform_version": "wheezy"
  },
  
  ## Example of AWS Box Definition
  "ubuntu_vivid": {
    "provider": "aws",
    "ami": "ami-b1443fc6",  ## Amazon Image ID
    "user": "ubuntu",       ## User which will be used for access to the box
    "default_instance_type": "m3.medium",  ## Amazon instance type
    "platform": "ubuntu",
    "platform_version": "vivid"
  }
}
```

#### Available options

* provider -- virtual machine provider
* box -- virtualbox image if provider is virtualbox
* ami -- AWS image if provider is Amazon
* platform  -- name of target platform
* platform_version -- name of version of platform
* user -- user which will be used to access to box
* default_instance_type -- default instance size/type if provider is amazon

### repo.d files

Repositories for products are described in json files. Each file could contain one or more repodefinitions (fields are commented below). During the start mdbci scans repo.d directory and builds full set of available product versions.

```
[
{
   "product":           "galera",
   "version":           "5.3.10",
   "repo":              "http://yum.mariadb.org/5.3.10/centos6-amd64",
   "repo_key":          "https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
   "platform":          "centos",
   "platform_version":  6
},
{
   "product":           "galera",
   "version":           "5.3.10",
   "repo":              "http://yum.mariadb.org/5.3.10/centos7-amd64",
   "repo_key":          "https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
   "platform":          "centos",
   "platform_version":  7
}
]
```
#### Available options

* product -- product name
* version -- product version
* repo -- link to the repo
* repo_key -- link to repo key
* platform  -- name of target platform
* platform_version -- name of version of platform

### template.json

Templates describe particular stand configuration and have json format. Usually templait contains next blocks:

  * Global config
  * Nodes definitions
  
#### Global config parameters

The are next global optional parameters

* cookbook_path -- replaces path to cookbooks.
* aws_config -- if AWS is used. It specifies [aws_config.yml](#awsconfigyml) file. **Note** If this parameter is specified, mdbci will all nodes interpret as AWS nodes.


#### Node definition

Node definition could contain next parameters:

* hostname -- name (and hostname) for VM instance
* box -- box mane according [boxes.json](#boxesjson) file
* product -- product block definition

Product block definition looks like as an example:

```
    "product" : {
      "name": "mariadb",
      "version": "10.0.20"
    }
```

For Galera product defined some additional parameters for galera server.cnf configuration, for example:

```
    "product" : {
      "name": "galera",
      "version": "10.0",
      "cnf_template" : "server1.cnf",
      "cnf_template_path" : "../cnf",
      "node_name" : "galera0"
    }
```

If you want to use non standard configuration for box/product (for instance, you need to install centos6 package with mariadb to centos7 with some particular version) you can use hard repo name link like 

```
    "product" : {
      "repo": "mariadb@10.0.20_centos6"
    }
```

Extra information about matching boxes, versions and products could be found in [corresponded section](#box-products-versions)


### aws_config.yml

This file contains parameters which are required for access to Amazon machines. We intentionally keep ньд format to have compatibility with other tools. Next keys are available in this file

* access_key_id -- AWS access key id
* secret_access_key --  secret access key
* keypair_name	-- private key name
* security_groups -- List of amazon security groups
* region -- AWS region
* pemfile -- pem file
* user_data -- extra user parameters
* public_ip_service -- curl to aws metadata for public ip4 address
* private_ip_service -- curl to aws metadata for private ip4 address

Here is an example

```
aws:
   access_key_id : 'your_access_key_id_from_aws'
   secret_access_key : 'your_secret_access_key_from_aws'
   keypair_name	: 'your_keypair_name'
   security_groups : [ 'default', 'vagrant' ]
   region : 'eu-west-1'	
   pemfile : '../maxscale.pem' 		# your private key
   user_data : "#!/bin/bash\nsed -i -e 's/^Defaults.*requiretty/# Defaults requiretty/g' /etc/sudoers"
   public_ip_service : "curl http://169.254.169.254/latest/meta-data/public-ipv4"
   private_ip_service : "curl http://169.254.169.254/latest/meta-data/private-ipv4"
```
