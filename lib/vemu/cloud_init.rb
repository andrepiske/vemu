
module Vemu
  #
  # https://cloudinit.readthedocs.io/en/latest/reference/examples.html
  #
  class CloudInit
    attr_accessor :users
    attr_accessor :host_name
    attr_accessor :instance_id

    def initialize(host_name:, instance_id: nil, context: Context.default)
      @timezone = 'Etc/UTC'
      @next_user_uid = 1001
      @users = []
      @instance_id = instance_id || host_name
      @host_name = host_name
    end

    def add_user(user_name, sudoer: false, ssh_keys: nil, uid: nil)
      unless uid
        uid = @next_user_uid
        @next_user_uid += 1
      end

      {
        name: user_name.to_s,
        uid: uid.to_s,
        homedir: "/home/#{user_name}",
        shell: '/bin/bash',
        lock_passwd: true,
      }.tap do |user|
        user[:sudo] = 'ALL=(ALL) NOPASSWD:ALL' if sudoer
        user[:ssh_authorized_keys] = Array(ssh_keys) if ssh_keys
        @users << user
      end
    end

    def create_isodisk(output_path:)
      # TODO: add dependency check => genisoimage --version
      #                            genisoimage 1.1.11 (Linux)
      temp_folder = File.join('/tmp/vemu-temp/', SecureRandom.alphanumeric(22))
      ci_path = File.join(temp_folder, 'cidata')
      FileUtils.mkdir_p(ci_path)

      File.write(File.join(ci_path, 'user-data'), user_data)
      File.write(File.join(ci_path, 'meta-data'), meta_data)

      all_files = [
        "#{ci_path}/user-data",
        "#{ci_path}/meta-data",
      ]
      command = "genisoimage -r -J -V cidata -input-charset utf-8 -o #{output_path} #{all_files.join(' ')}"
      `#{command}`

      FileUtils.rm_rf(temp_folder)

      true
    end

    def meta_data
      data = {
        'instance-id' => @instance_id,
        'local-hostname' => @host_name,
      }

      yaml_data = Psych.dump(data, stringify_names: true)
      "#{yaml_data.split("\n")[1..].join("\n")}\n"
    end

    def user_data
      ci_data = {
        growpart: {
          mode: 'auto',
          devices: ['/'],
        },

        # mounts:
        timezone: @timezone,

        users:,

        final_message: <<~INFO,
          cloud-init has finished
          version: $version
          timestamp: $timestamp
          datasource: $datasource
          uptime: $uptime
        INFO
      }

      yaml_data = Psych.dump(ci_data, stringify_names: true)

      "\#cloud-config\n#{yaml_data.split("\n")[1..].join("\n")}\n"
    end
  end
end
