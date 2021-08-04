require 'rails_helper'

RSpec.describe ParseVkFileWorker do
  subject(:instance) { described_class.new }

  context 'in vk_error.html' do
    let(:file) { File.open(file_fixture('vk_error.html'), 'rb') }

    it 'identifies vk error' do
      expect(instance.vk_error?(file)).to be_truthy
    end
  end

  context 'in Ananas_v_narezku.siq' do
    let(:file) { File.open(file_fixture('Ananas_v_narezku.siq'), 'rb') }

    it 'does not have vk error' do
      expect(instance.vk_error?(file)).to be_falsey
    end
  end
end
