require 'rails_helper'

RSpec.describe Si::Package do
  describe '.read_from_siq' do
    let(:zip_buffer) { File.open(file_fixture('Ananas_v_narezku.siq'))}
    subject(:package) { described_class.read_from_siq(zip_buffer) }

    it 'has authors' do
      expect(package.authors).to eq(['Fl Studio'])
    end

    it 'has name' do
      expect(package.name).to eq('Ананас в нарезку')
    end
  end
end
