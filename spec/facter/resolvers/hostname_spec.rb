# frozen_string_literal: true

describe Facter::Resolvers::Hostname do
  subject(:hostname_resolver) { Facter::Resolvers::Hostname }

  describe '#resolve' do
    before do
      allow(Socket).to receive(:gethostname).and_return(host)
      allow(Facter::Util::FileHelper).to receive(:safe_read)
        .with('/etc/resolv.conf')
        .and_return("nameserver 10.10.0.10\nnameserver 10.10.1.10\nsearch baz\ndomain baz\n")
    end

    after do
      hostname_resolver.invalidate_cache
    end

    context 'when hostname returns fqdn' do
      let(:hostname) { 'foo' }
      let(:domain) { 'bar' }
      let(:host) { "#{hostname}.#{domain}" }
      let(:fqdn) { "#{hostname}.#{domain}" }

      it 'detects hostname' do
        expect(hostname_resolver.resolve(:hostname)).to eql(hostname)
      end

      it 'returns networking Domain' do
        expect(hostname_resolver.resolve(:domain)).to eq(domain)
      end

      it 'returns fqdn' do
        expect(hostname_resolver.resolve(:fqdn)).to eq(fqdn)
      end
    end

    context 'when hostname returns host' do
      let(:hostname) { 'foo' }
      let(:domain) { 'baz' }
      let(:host) { hostname }
      let(:fqdn) { "#{hostname}.#{domain}" }

      before do
        allow(Addrinfo).to receive(:getaddrinfo).and_return([])
      end

      it 'detects hostname' do
        expect(hostname_resolver.resolve(:hostname)).to eql(hostname)
      end

      it 'returns networking Domain' do
        expect(hostname_resolver.resolve(:domain)).to eq(domain)
      end

      it 'returns fqdn' do
        expect(hostname_resolver.resolve(:fqdn)).to eq(fqdn)
      end
    end

    context 'when hostname returns host and addrinfo returns the fqdn' do
      let(:hostname) { 'foo' }
      let(:domain) { 'bar' }
      let(:host) { hostname }
      let(:fqdn) { "#{hostname}.#{domain}" }

      before do
        allow(Addrinfo).to receive(:getaddrinfo)
          .and_return([instance_double(Addrinfo, canonname: fqdn, ip_address: '10.0.0.1')])
      end

      it 'bounds the lookup with a timeout when Ruby honours it' do
        stub_const('RUBY_ENGINE', 'ruby')
        stub_const('RUBY_VERSION', '4.0.0')

        hostname_resolver.resolve(:fqdn)

        expect(Addrinfo).to have_received(:getaddrinfo)
          .with(hostname, 0, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME,
                timeout: Facter::Resolvers::Hostname::FQDN_LOOKUP_TIMEOUT)
      end

      it 'omits the timeout when Ruby does not honour it' do
        stub_const('RUBY_ENGINE', 'ruby')
        stub_const('RUBY_VERSION', '3.4.0')

        hostname_resolver.resolve(:fqdn)

        expect(Addrinfo).to have_received(:getaddrinfo)
          .with(hostname, 0, Socket::AF_UNSPEC, Socket::SOCK_STREAM, nil, Socket::AI_CANONNAME)
      end

      it 'returns networking Domain' do
        expect(hostname_resolver.resolve(:domain)).to eq(domain)
      end

      it 'returns fqdn' do
        expect(hostname_resolver.resolve(:fqdn)).to eq(fqdn)
      end
    end

    context 'when hostname returns host and addrinfo times out' do
      let(:host) { 'foo' }

      let(:timeout_error) { defined?(IO::TimeoutError) ? IO::TimeoutError : Errno::ETIMEDOUT }

      before do
        allow(Addrinfo).to receive(:getaddrinfo).and_raise(timeout_error, 'user specified timeout')
      end

      it 'detects domain from resolv.conf' do
        expect(hostname_resolver.resolve(:domain)).to eq('baz')
      end
    end

    context 'when hostname could not be retrieved' do
      let(:host) { nil }

      it 'detects that hostname is nil' do
        expect(hostname_resolver.resolve(:hostname)).to be_nil
      end
    end

    context 'when /etc/resolve.conf is inaccessible' do
      let(:host) { 'foo' }
      let(:domain) { '' }

      before do
        allow(Facter::Util::FileHelper).to receive(:safe_read).with('/etc/resolv.conf').and_return('')
        allow(Addrinfo).to receive(:getaddrinfo).and_return([])
      end

      it 'detects that domain is nil' do
        expect(hostname_resolver.resolve(:domain)).to be_nil
      end
    end

    context 'when getaddrinfo throws exception' do
      let(:host) { 'foo' }

      before do
        allow(Addrinfo).to receive(:getaddrinfo).and_raise('socket exception')
      end

      it 'detects domain from resolv.conf' do
        expect(hostname_resolver.resolve(:domain)).to eq('baz')
      end
    end
  end
end
