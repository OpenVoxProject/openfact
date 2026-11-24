# frozen_string_literal: true

describe Facts::Opnsense::Os::Name do
  describe '#call_the_resolver' do
    subject(:fact) { Facts::Opnsense::Os::Name.new }

    before do
      allow(Facter::Resolvers::Opnsense::OpnsenseVersion).to receive(:resolve).with(:name).and_return(value)
    end

    context 'when name is retrieved from opnsense-version' do
      let(:value) { 'OPNsense' }

      it 'returns operating system name fact' do
        expect(fact.call_the_resolver).to be_an_instance_of(Array).and \
          contain_exactly(an_object_having_attributes(name: 'os.name', value: value),
                          an_object_having_attributes(name: 'operatingsystem', value: value, type: :legacy))
      end
    end

    context 'when name can\'t be received' do
      let(:value) { nil }

      it 'returns OPNsense as operating system name fact' do
        expect(fact.call_the_resolver).to be_an_instance_of(Array).and \
          contain_exactly(an_object_having_attributes(name: 'os.name', value: 'OPNsense'),
                          an_object_having_attributes(name: 'operatingsystem', value: 'OPNsense', type: :legacy))
      end
    end
  end
end
