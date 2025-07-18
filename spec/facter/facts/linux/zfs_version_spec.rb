# frozen_string_literal: true

describe Facts::Linux::ZfsVersion do
  describe '#call_the_resolver' do
    subject(:fact) { Facts::Linux::ZfsVersion.new }

    let(:version) { '6' }

    before do
      allow(Facter::Resolvers::ZFS).to receive(:resolve).with(:zfs_version).and_return(version)
    end

    it 'returns zfs_version fact' do
      expect(fact.call_the_resolver).to be_an_instance_of(Facter::ResolvedFact).and \
        have_attributes(name: 'zfs_version', value: version)
    end
  end
end
