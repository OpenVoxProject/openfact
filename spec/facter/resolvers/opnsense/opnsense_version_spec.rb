# frozen_string_literal: true

describe Facter::Resolvers::Opnsense::OpnsenseVersion do
  subject(:opnsense_version) { Facter::Resolvers::Opnsense::OpnsenseVersion }

  before do
    opnsense_version.invalidate_cache
    allow(Facter::Core::Execution).to receive(:execute)
      .with('/usr/local/sbin/opnsense-version -NVv', { logger: opnsense_version.log })
      .and_return(output)
  end

  context 'when opnsense-version returns output' do
    let(:output) { "OPNsense 26.1 26.1.2_1\n" }

    it 'returns name' do
      expect(opnsense_version.resolve(:name)).to eq('OPNsense')
    end

    it 'returns series' do
      expect(opnsense_version.resolve(:series)).to eq('26.1')
    end

    it 'returns version' do
      expect(opnsense_version.resolve(:version)).to eq('26.1.2_1')
    end
  end

  context 'when opnsense-version returns incomplete output' do
    let(:output) { "Missing /usr/local/opnsense/version/core\n" }

    it 'returns nil for name' do
      expect(opnsense_version.resolve(:name)).to be_nil
    end

    it 'returns nil for version' do
      expect(opnsense_version.resolve(:version)).to be_nil
    end
  end

  context 'when opnsense-version is not available' do
    let(:output) { '' }

    it 'returns nil for series' do
      expect(opnsense_version.resolve(:series)).to be_nil
    end

    it 'executes opnsense-version only once' do
      opnsense_version.resolve(:name)
      opnsense_version.resolve(:version)

      expect(Facter::Core::Execution).to have_received(:execute).once
    end
  end
end
