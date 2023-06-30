require 'rails_helper'

RSpec.describe ParseVkFileWorker do
  subject(:instance) { described_class.new }

  context 'in vk_error.html' do
    let(:file) { File.open(file_fixture('vk_error.html'), 'rb') }

    it 'identifies vk error' do
      expect(instance.vk_error?(file)).to be_truthy
    end
  end

  context 'in real siq file' do
    let(:file) { File.open(file_fixture('SIGameTest.siq'), 'rb') }

    it 'does not have vk error' do
      expect(instance.vk_error?(file)).to be_falsey
    end
  end

  describe '#clean_url', focus: true do
    it 'preserves only hash' do
      initial = 'https://vk.com/doc1922_297?hash=5cc&dl=A:16473:fa06f4&api=1&no_preview=1'

      expect(instance.clean_url(initial))
        .to eq('https://vk.com/doc1922_297?hash=5cc')
    end
  end
end
