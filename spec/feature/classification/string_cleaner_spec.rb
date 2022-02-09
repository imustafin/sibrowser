require 'rails_helper'

RSpec.describe Classification::StringCleaner do
  describe '#has_foreign?' do
    let(:instance) { described_class.new }

    specify 'English is not foreign' do
      expect(instance.has_foreign?('abc i')).to be_falsey
    end

    specify 'Russian is not foreign' do
      expect(instance.has_foreign?('абв й ы ё')).to be_falsey
    end

    specify 'Latin accents are foreign' do
      expect(instance.has_foreign?('á')).to be_truthy
    end

    specify 'Cyrillic Schwa is foreign' do
      expect(instance.has_foreign?('ә')).to be_truthy
    end

    specify 'Greek is foreign' do
      expect(instance.has_foreign?('αβγ')).to be_truthy
    end
  end

  describe '#clean' do
    let(:instance) { described_class.new }

    it 'removes special characters' do
      expect(instance.clean('абв, где?')).to eq('абв где')
    end

    it 'removes Japanese' do
      expect(instance.clean('NARUTO ナルト')).to eq('naruto')
    end

    it 'downcases' do
      expect(instance.clean('ABC')).to eq('abc')
    end

    it 'removes long words' do
      expect(instance.clean('and then aaaaaaaaaaaaaaaaaaaaaaaaa'))
        .to eq('and then')
    end

    it 'removes 1-letter words' do
      expect(instance.clean('a b и й longer'))
        .to eq('longer')
    end
  end

  describe '#clean_sentences' do
    let(:instance) { described_class.new }

    it 'skips sentences with foreign chars' do
      expect(instance.clean_sentences(%w[English Türkçe]))
        .to contain_exactly('english')
    end
  end
end
