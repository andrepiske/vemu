#!/usr/bin/env ruby
require 'socket'
require 'fcntl'
require 'json'
puts "Start vemu guestagent"

lsb_info = `lsb_release -a`
puts lsb_info

path = "/dev/virtio-ports/io.vemu.guest_agent.0"
fd = IO.sysopen(path, Fcntl::O_NOCTTY | Fcntl::O_RDWR)
fp = File.open(fd)
fp.sync = true

fp.write("#{JSON.dump({ info: lsb_info })}\n")
fp.write("#{JSON.dump({ info: '--finished--' })}\n")
