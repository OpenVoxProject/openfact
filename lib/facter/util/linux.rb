# frozen_string_literal: true

module Facter
  module Util
    module Linux
      def self.process_running?(process_name)
        pidfiles = Dir.glob("{/run,/var/run}/#{process_name}{,*,/}*.pid")
        pidfiles.each do |pf|
          next unless File.file?(pf)

          pid = begin
            Integer(Facter::Util::FileHelper.safe_read(pf, '').strip, 10)
          rescue StandardError
            nil
          end
          next unless pid&.positive?

          begin
            # Doesn't actually kill, just detects if the process exists
            Process.kill(0, pid)
            return true if proc_comm(pid) == process_name || proc_cmdline(pid)&.match?(%r{(^|\s|/)#{process_name}(\s|$)})
          rescue Errno::ESRCH
            # If we can't confirm identity, still treat it as not running to be safe.
            next
          rescue Errno::EPERM
            # Exists but we can't inspect it; assume it's running.
            return true
          end
        end

        # Fallback: Try to find it in /proc
        return false unless Dir.exist?('/proc')

        Dir.glob('/proc/[0-9]*/comm').any? do |path|
          Facter::Util::FileHelper.safe_read(path, nil)&.strip == process_name
        end
      end

      def self.proc_comm(pid)
        Facter::Util::FileHelper.safe_read("/proc/#{pid}/comm", nil)&.strip
      end

      def self.proc_cmdline(pid)
        raw = Facter::Util::FileHelper.safe_read("/proc/#{pid}/cmdline", nil)
        raw&.tr("\0", ' ')
      end
    end
  end
end
