# -*- mode: ruby -*-
# vi: set ft=ruby :

# Shoehorn the config file into our test Vagrantfile
require_relative File.join(File.expand_path(Dir.pwd), 'templates/class_config.rb')

# config_file = 'vm-config.yml-example'
dreambox_config_file = (defined?(config_file)) ? config_file : 'vm-config.yml'

Dreambox = Config.new(dreambox_config_file)

Vagrant.configure(2) do |config|
<<<<<<< HEAD
# I would rather use ubuntu/trust64 because that appears to be the build that's used on my shared hosting
  #  config.vm.box = "hashicorp/precise64"
  config.vm.box = "ubuntu/trusty64"
# This is deleted because hashicorp recently removed the forwarding... vagrantcloud is the default and it's working just fine.
  #config.vm.box_url = "https://atlas.hashicorp.com/hashicorp/boxes/precise64"
=======
  config.vm.box = "ubuntu/trusty64"
  config.vm.box_url = "https://vagrantcloud.com/ubuntu/boxes/trusty64"
>>>>>>> 0.3.0-base

  config.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true

# This is to get it to work on my work computer. Totally unsecure, but I can't resolve anything with apt-get if I don't
  config.vm.network "public_network"

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  # Recreates the Packer file provisioner
  files = {
    'files' => '/tmp/',
  }
  files.each { | dir, path | config.vm.provision "file", source: "#{dir}", destination: "#{path}" }

  # Development machine
  # Ubuntu 14.04
  config.vm.define 'dev', autostart: false do |dev|
    dev.vm.hostname = "dreambox.dev"
    dev.vm.network :private_network, ip: "192.168.12.34"
  end

  # Testing machine
  # To be fully provisioned and ready to test
  config.vm.define 'test', primary: true do |test|
    test.vm.hostname = "dreambox.test"
    test.vm.network :private_network, ip: "192.168.56.78"

<<<<<<< HEAD
    # Sets up the sync folder
    test.vm.synced_folder 'web', '/home/db_user/dreambox.com', create = true
=======
    config.vm.provider "virtualbox" do |vb|
      vb.name = "Dreambox"
    end
>>>>>>> 0.3.0-base

    # Start bash as a non-login shell
    test.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

    test.vm.provision "Set Files",
      type: "shell",
      path: "provisioners/set-files.sh"

    test.vm.provision "Base",
      type: "shell",
      path: "provisioners/base.sh"

    test.vm.provision "Apache Setup",
      type: "shell",
<<<<<<< HEAD
      path: "scripts/base.sh"
=======
      path: "provisioners/setup.apache.sh"

    test.vm.provision "MySQL Setup",
      type: "shell",
      path: "provisioners/setup.mysql.sh"

    if Dreambox.config['ssl_enabled'] then
      test.vm.provision "SSL Setup",
        type: "shell",
        inline: "/bin/bash /usr/local/dreambox/ssl.sh",
        :env => Dreambox.config
    end

    Dreambox.config['sites'].each do |site, conf|
      test.vm.provision "User Setup: #{conf['user']}",
        type: "shell",
        inline: "/bin/bash /usr/local/dreambox/user.sh",
        :env => conf

      if (! conf['is_subdomain']) then
        test.vm.synced_folder conf['sync'], conf['sync_destination'],
          owner: "#{conf['uid']}",
          group: "#{conf['gid']}",
          mount_options: ["dmode=775,fmode=664"]
      end

      test.vm.provision "VHost Setup: #{conf['host']}",
        type: "shell",
        inline: "/bin/bash /usr/local/dreambox/vhost.sh",
        :env => conf
    end
>>>>>>> 0.3.0-base

    test.vm.provision "Start Apache",
      type: "shell",
      inline: "/bin/bash /etc/init.d/httpd2 start"
  end
end
