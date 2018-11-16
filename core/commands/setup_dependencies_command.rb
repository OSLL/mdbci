# frozen_string_literal: true

require_relative 'base_command'
require_relative '../services/shell_commands'

class SetupDependenciesCommand < BaseCommand
    def self.synopsis
        'Installs vagrant and its dependencies'
    end

    def execute

    end

    # Extracts linus distributor id from lsb_release command
    def get_linux_distro
        lsb_distributor_regex = /^Distributor ID:\s*(\w+)$/
        lsb_output = ShellCommands.run_command($out, 'lsb_release -a')
        lsb_output.each do |line|
            return line.match(lsb_distributor_regex)[1] if line =~ lsb_distributor_regex
        end
    end
