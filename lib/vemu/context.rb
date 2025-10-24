module Vemu
  class Context
    BASE_IMAGES = {
      ubuntu: [
        {
          url: 'https://cloud-images.ubuntu.com/releases/noble/release-20250704/ubuntu-24.04-server-cloudimg-amd64.img',
          arch: 'amd64',
          digest: 'sha256:f1652d29d497fb7c623433705c9fca6525d1311b11294a0f495eed55c7639d1f',
        },
        {
          url: 'https://cloud-images.ubuntu.com/releases/noble/release-20250704/ubuntu-24.04-server-cloudimg-arm64.img',
          arch: 'aarch64',
          digest: 'sha256:bbecbb88100ee65497927ed0da247ba15af576a8855004182cf3c87265e25d35',
        }
      ]
    }

    def self.default
      @default_context ||= new
    end

    attr_accessor :vemu_folder

    def initialize
      @vemu_folder = File.expand_path(File.join(ENV['HOME'], '.vemu'))
    end

    def path_for_vm(vm_name)
      File.join(@vemu_folder, 'vms', vm_name)
    end

    def base_image_path(name:, arch: 'amd64')
      find_image(name, arch)
      File.join(@vemu_folder, 'base-images', "#{name}-#{arch}.img")
    end

    def find_image(name, arch)
      BASE_IMAGES[name.to_sym].find { |img| img[:arch] == arch  }
    end
  end
end
