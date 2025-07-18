# frozen_string_literal: true

describe Facts::Linux::Hypervisors::Lxc do
  describe '#call_the_resolver' do
    subject(:fact) { Facts::Linux::Hypervisors::Lxc.new }

    before do
      allow(Facter::Resolvers::Linux::Containers).to \
        receive(:resolve).with(:hypervisor).and_return(hv)
    end

    context 'when resolver returns lxc' do
      let(:hv) { { lxc: { 'name' => 'test_name' } } }
      let(:value) { { 'name' => 'test_name' } }

      it 'returns virtual fact' do
        expect(fact.call_the_resolver).to be_an_instance_of(Facter::ResolvedFact).and \
          have_attributes(name: 'hypervisors.lxc', value: value)
      end
    end

    context 'when resolver returns docker' do
      let(:hv) { { docker: { 'id' => 'testid' } } }

      it 'returns virtual fact as nil' do
        expect(fact.call_the_resolver).to be_an_instance_of(Facter::ResolvedFact).and \
          have_attributes(name: 'hypervisors.lxc', value: nil)
      end
    end

    context 'when resolver returns nil' do
      let(:hv) { nil }

      it 'returns virtual fact as nil' do
        expect(fact.call_the_resolver).to be_an_instance_of(Facter::ResolvedFact).and \
          have_attributes(name: 'hypervisors.lxc', value: hv)
      end
    end

    context 'when lxc info is empty' do
      let(:hv) { { lxc: {} } }
      let(:value) { {} }

      it 'returns virtual fact as empty array' do
        expect(fact.call_the_resolver).to be_an_instance_of(Facter::ResolvedFact).and \
          have_attributes(name: 'hypervisors.lxc', value: value)
      end
    end
  end
end
