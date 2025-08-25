# frozen_string_literal: true

desc 'Build Facter manpages'
task :gen_manpages do
  require 'fileutils'

  FileUtils.mkdir_p('./man/man1')

  sh 'RUBYLIB=./lib:$RUBYLIB bin/facter --man > ./man/man1/facter.1'
end
