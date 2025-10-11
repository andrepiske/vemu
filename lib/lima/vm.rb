
class Lima::VM
  attr_accessor :name
  attr_accessor :cpus
  attr_accessor :memory
  attr_accessor :driver
  attr_accessor :arch

  def initialize
    @driver = 'vz'
    @arch = 'aarch64'

    @template = "template://_images/ubuntu-24.04"
  end

  def start_command
    [
      "limactl", "start",
      "-y", "--log-format=json",
      "--name=#{@name}",
      # "--arch=#{@arch}",
      "--cpus=#{@cpus}",
      "--memory=#{@memory}",
      # "--vm-type=#{@driver}",
      # "--network=lima:shared",
      @template,
    ]
  end

  def ssh_start(&blk)
    Net::SSH.start("lima-#{@name}", nil, config: ssh_config_path, &blk)
  end

  def ssh_config
    File.read(ssh_config_path)
  end

  def ssh_config_path
    File.expand_path File.join(ENV['HOME'], ".lima/#{@name}/ssh.config")
  end
end
