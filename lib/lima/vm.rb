
class Lima::VM
  attr_accessor :name
  attr_accessor :cpus
  attr_accessor :memory
  attr_accessor :driver
  attr_accessor :arch
  attr_accessor :disk
  attr_accessor :plain

  def initialize
    @plain = false
    @driver = 'vz' if OS.x?
    @arch = {
      'arm64' => 'aarch64'
    }.fetch(OS.host_cpu, OS.host_cpu)

    @template = "template://_images/ubuntu-24.04"
  end

  def started?
    # theoretically the presence of ha.sock should already flag this
    # but we're betting that it is fully started and not just starting.
    File.file?(File.join(vm_basepath, "ssh.sock"))
  end

  def exist?
    File.file?(File.join(vm_basepath, "lima.yaml"))
  end

  def create(start: false, verbose: false)
    run_command_local(create_command(start:), verbose:)
  end

  def start(verbose: false)
    create(start: true, verbose:)
  end

  def stop(verbose: false)
    run_command_local(stop_command, verbose:)
  end

  def rm(force: false, verbose: false)
    run_command_local(rm_command(force:), verbose:)
  end

  def rm!
    rm(force: true)
  end

  def run_command_local(cmd, verbose:)
    puts "Run: #{cmd.join(' ')}" if verbose

    si, so, ww = Open3.popen2e(*cmd)
    si.close

    lines_read = []
    while !so.eof?
      line = so.gets

      lines_read << line

      puts "#{line}" if verbose
    end

    success = (ww.value.exitstatus == 0)
    unless success
      puts "ERROR: command returned non-zero status code (#{ww.value.exitstatus})"
      puts "command: #{cmd.join(' ')}"
      puts lines_read
      puts "-------"
    end

    return success, lines_read, ww.value.exitstatus
  end

  def stop_command(json_output: true)
    [
      "limactl", "stop",
      "-y", "--log-format=#{json_output ? 'json' : 'text'}",
      @name
    ]
  end

  def rm_command(force: false, json_output: true)
    [
      "limactl", "rm",
      "-y", "--log-format=#{json_output ? 'json' : 'text'}",
      force ? "-f" : nil,
      @name
    ].compact
  end

  def create_command(start: false, json_output: true)
    [
      "limactl", start ? "start" : "create",
      "-y", "--log-format=#{json_output ? 'json' : 'text'}",
      "--name=#{@name}",
      @cpus ? "--cpus=#{@cpus}" : nil,
      @memory ? "--memory=#{@memory}" : nil,

      @arch ? "--arch=#{@arch}" : nil,
      @driver ? "--vm-type=#{@driver}" : nil,
      @disk ? "--disk=#{@disk}" : nil,

      @plain ? "--plain" : nil,

      # "--network=lima:shared",

      @template,
    ].compact
  end

  def ssh_start(&blk)
    Net::SSH.start("lima-#{@name}", nil, config: ssh_config_path, &blk)
  end

  def ssh_config_path
    File.join(vm_basepath, 'ssh.config')
  end

  def vm_basepath
    File.join(lima_basepath, @name)
  end

  def lima_basepath
    File.expand_path(File.join(ENV['HOME'], '.lima'))
  end
end
