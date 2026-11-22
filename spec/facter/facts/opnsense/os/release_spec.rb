# frozen_string_literal: true

describe Facts::Opnsense::Os::Release do
  describe '#call_the_resolver' do
    subject(:fact) { Facts::Opnsense::Os::Release.new }

    before do
      allow(Facter::Resolvers::Opnsense::OpnsenseVersion).to receive(:resolve).with(:series).and_return(series)
      allow(Facter::Resolvers::Opnsense::OpnsenseVersion).to receive(:resolve).with(:version).and_return(version)
    end

    context 'when version has a minor release' do
      let(:series) { '26.1' }
      let(:version) { '26.1.2' }
      let(:release) { { 'full' => '26.1.2', 'major' => '26.1', 'minor' => '2' } }

      it 'returns operating system release fact' do
        expect(fact.call_the_resolver).to be_an_instance_of(Array).and \
          contain_exactly(an_object_having_attributes(name: 'os.release', value: release),
                          an_object_having_attributes(name: 'operatingsystemmajrelease',
                                                      value: release['major'], type: :legacy),
                          an_object_having_attributes(name: 'operatingsystemrelease',
                                                      value: release['full'], type: :legacy))
      end
    end

    context 'when version has a package revision' do
      let(:series) { '26.1' }
      let(:version) { '26.1.2_1' }
      let(:release) { { 'full' => '26.1.2_1', 'major' => '26.1', 'minor' => '2_1' } }

      it 'returns operating system release fact' do
        expect(fact.call_the_resolver).to be_an_instance_of(Array).and \
          contain_exactly(an_object_having_attributes(name: 'os.release', value: release),
                          an_object_having_attributes(name: 'operatingsystemmajrelease',
                                                      value: release['major'], type: :legacy),
                          an_object_having_attributes(name: 'operatingsystemrelease',
                                                      value: release['full'], type: :legacy))
      end
    end

    context 'when version has no minor release' do
      let(:series) { '26.1' }
      let(:version) { '26.1' }
      let(:release) { { 'full' => '26.1', 'major' => '26.1' } }

      it 'returns operating system release fact' do
        expect(fact.call_the_resolver).to be_an_instance_of(Array).and \
          contain_exactly(an_object_having_attributes(name: 'os.release', value: release),
                          an_object_having_attributes(name: 'operatingsystemmajrelease',
                                                      value: release['major'], type: :legacy),
                          an_object_having_attributes(name: 'operatingsystemrelease',
                                                      value: release['full'], type: :legacy))
      end
    end

    context 'when release can\'t be received' do
      let(:series) { nil }
      let(:version) { nil }

      it 'returns operating system release fact as nil' do
        expect(fact.call_the_resolver).to be_an_instance_of(Facter::ResolvedFact).and \
          have_attributes(name: 'os.release', value: nil)
      end
    end
  end
end
