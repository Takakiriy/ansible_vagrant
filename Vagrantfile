Vagrant.configure("2") do |config|

  #// Common VM settings
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024  #// MB
  end

  #// synchronized folder
  config.vm.synced_folder ".", "/vagrant",  create: true, owner: "vagrant", group: "vagrant", type:"virtualbox"

  #// Control node (server)
  config.vm.define "centos7_51" do |config|

    config.vm.box = "centos/7"
    config.vm.network :private_network, ip: "192.168.34.51"
    config.vm.network :forwarded_port, guest: 22, host: 2351, id: "ssh"

    #// Guest Additions
    config.vbguest.installer_options = { allow_kernel_upgrade: true }  #search: vagrant-vbguest plug-in

    #// Ansible
    config.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "playbook-0.yml"
      ansible.compatibility_mode = '2.0'
      ansible.raw_arguments = ['--check']
    end
  end

  #// Proxy
  if Vagrant.has_plugin?("vagrant-proxyconf") && ENV['HTTP_PROXY'] && ENV['HTTPS_PROXY']
    config.proxy.http     = ENV['HTTP_PROXY']
    config.proxy.https    = ENV['HTTPS_PROXY']
    config.proxy.no_proxy = "localhost, 127.0.0.1, 192.168.*, 192.168.34.51, centos7_51"
  end
end
