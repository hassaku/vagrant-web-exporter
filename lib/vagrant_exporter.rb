class VagrantExporter
  def initialize(vagrant_root)
    @vagrant_root = vagrant_root
  end

  def instruction(name, url)
    script = <<EOS
#!/usr/bin/env bash

echo '- Import VM'
vagrant box add #{name} #{url}/packages/#{name}.box
cd #{@vagrant_root}
EOS

    if Dir::entries("public/shared_folders/").include?("#{name}.tar.gz")
      script << <<EOS

echo '- Download vagrant project files'
curl -o #{name}.tar.gz #{url}/shared_folders/#{name}.tar.gz
tar zxfv #{name}.tar.gz > /dev/null
rm #{name}.tar.gz
cd #{name}
EOS
    else
      script << <<EOS

echo '- Create the vagrant config file'
mkdir #{name}
cd #{name}
cat > Vagrantfile << EOF
Vagrant::Config.run do |config|
  config.vm.box = "#{name}"
  config.vm.name = "#{name}"
end
EOF
EOS
    end
    script << <<EOS

echo '- Start VM'
vagrant up

echo '- Login VM'
vagrant ssh
EOS

    File.write("public/scripts/#{name}-install", script)
    instruction = <<EOS
$ bash < <(curl -s #{url}/scripts/#{name}-install)
EOS
  end

  def export(name)
    vbox_list, error = Open3.capture3("VBoxManage list vms")
    vbox_list.split("\n").each do |l|
      if name == l.match(/\"(.*)\"/)[0].delete("\"").gsub(/_\d+$/, "")
        break
      end
    end

    dir_name = File.expand_path(File.dirname(__FILE__))
    vagrantfile_available = Dir::entries("#{@vagrant_root}/#{name}/").include?("Vagrantfile")
    tar_command = "(cd '#{@vagrant_root}';tar zcvf #{dir_name}/../public/shared_folders/#{name}.tar.gz ./#{name})"
    package_command = "vagrant package --base #{name} --output #{dir_name}/../public/packages/#{name}.box"

    # background task
    EM::defer do
      if vagrantfile_available
        File.write("log/log.txt", "save archived files\n", mode:"a")
        File.write("log/log.txt", tar_command+"\n", mode:"a")
        out = system(tar_command)
        File.write("log/log.txt", out.to_s + "\n", mode:"a")
        p "created! tar.gz"
      end
      File.write("log/log.txt", "save vagrant box\n", mode:"a")
      File.write("log/log.txt", package_command+"\n", mode:"a")
      out, error = Open3.capture3(package_command)
      File.write("log/log.txt", out+"\n", mode:"a")
      File.write("log/log.txt", error+"\n", mode:"a")
      p "created! vbox."
    end
    p "creating.... it takes for long time.."
  end
end
