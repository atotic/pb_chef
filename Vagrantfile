# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "pb4us"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/20130910/raring-server-cloudimg-amd64-vagrant-disk1.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network :private_network, ip: "192.168.2.11"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  config.ssh.forward_agent = true
  # config.ssh.private_key_path = '/home/paul/.ssh/id_rsa'

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "4096"]
  end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file pb4us.pp in the manifests_path directory.
  #
  # An example Puppet manifest to provision the message of the day:
  #
  # # group { "puppet":
  # #   ensure => "present",
  # # }
  # #
  # # File { owner => 0, group => 0, mode => 0644 }
  # #
  # # file { '/etc/motd':
  # #   content => "Welcome to your Vagrant-built virtual machine!
  # #               Managed by Puppet.\n"
  # # }
  #
  # config.vm.provision :puppet do |puppet|
  #   puppet.manifests_path = "manifests"
  #   puppet.manifest_file  = "init.pp"
  # end

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #


  # Use `vagrant plugin install vagrant-librarian-chef` for this line:
  config.librarian_chef.cheffile_dir = '.'

  # Use `vagrant plugin install vagrant-omnibus` for this line:
  config.omnibus.chef_version = '11.6.0'

=begin
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe "root_ssh_agent::ppid"
    chef.add_recipe "ssh_agent_forwarding"
    chef.add_recipe "pookio::users"
  end
=end

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    # chef.roles_path = "roles"
    chef.data_bags_path = "data_bags"
    chef.add_recipe "root_ssh_agent::ppid"
    chef.add_recipe "ssh_agent_forwarding"
    chef.add_recipe "ruby_build"
    chef.add_recipe "rbenv::system"
    chef.add_recipe "postgresql::server"
    chef.add_recipe "postgresql::client"
    chef.add_recipe "nginx::source"
    chef.add_recipe "pookio"
 
    # You may also specify custom JSON attributes:
    chef.json = {
      "fqdn" => "dev.pook.io",
      "node_hostname" => "dev",
      
      "rbenv" => {
        "rubies" => ["2.0.0-p247"],
        "global" => "2.0.0-p247"
      },

      "nginx" => {
        "version" => "1.4.1",
        "dir" => "/opt/nginx-1.4.1",
        "user" => "nginx",
        "keepalive" => "on",
        "gzip" => "on",
        "gzip_types" => [
          "text/plain",
          "text/css",
          "application/x-javascript",
          "text/xml",
          "application/xml",
          "application/xml+rss",
          "application/rss+xml",
          "text/javascript",
          "application/javascript",
          "application/json",
          "application/x-font-ttf",
          "font/opentype",
          "application/vnd.ms-fontobject",
          "image/svg+xml"
        ],
        "init_style" => "init",
        "default_site_enabled" => false,
        "source" => {
          "modules" => ["http_ssl_module", "http_gzip_static_module"]
        }
      },

      "postgresql" => {
        "version" => "9.1",
        "password" => {
          "postgres" => "md5f0dfb42476ad991d2b47954d13d102a8"
        }
      },

      "pookio" => {
        "hostname" => "dev.pook.io"
      }
    }
  end

  # Enable provisioning with chef server, specifying the chef server URL,
  # and the path to the validation key (relative to this Vagrantfile).
  #
  # The Opscode Platform uses HTTPS. Substitute your organization for
  # ORGNAME in the URL and validation key.
  #
  # If you have your own Chef Server, use the appropriate URL, which may be
  # HTTP instead of HTTPS depending on your configuration. Also change the
  # validation key to validation.pem.
  #
  # config.vm.provision :chef_client do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
  #
  # If you're using the Opscode platform, your validator client is
  # ORGNAME-validator, replacing ORGNAME with your organization name.
  #
  # If you have your own Chef Server, the default validation client name is
  # chef-validator, unless you changed the configuration.
  #
  #   chef.validation_client_name = "ORGNAME-validator"
end
