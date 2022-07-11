require 'rails_helper'

RSpec.describe Si::Package do
  context 'in Ananas_v_narezku.siq' do
    let(:zip_buffer) { File.open(file_fixture('Ananas_v_narezku.siq'))}
    subject(:package) { described_class.new(zip_buffer) }

    it 'has authors' do
      expect(package.authors).to eq(['Fl Studio'])
    end

    it 'has name' do
      expect(package.name).to eq('Ананас в нарезку')
    end

    it 'has structure' do
      expect(package.structure).to include(
        {
          name: '1-й раунд',
          themes: include(
            {
              name: 'География',
              questions: include(
                answers: ['Гренландия'],
                question_text: 'Какой остров самый большой в мире?',
                question_types: ['text']
              )
            },
            {
              name: 'Юмористы',
              questions: include(
                answers: ['Петросян'],
                question_text: '',
                question_types: ['image']
              )
            }
          )
        }
      )
    end
  end

  context 'in Axel6Anime_With_Time2hack.siq' do
    let(:file) { File.open(file_fixture('Axel6Anime_With_Time2hack.siq')) }
    subject(:package) { described_class.new(file) }

    it 'has authors' do
      expect(package.authors).to eq(['Axel_Trevors', 'Time2Hack'])
    end

    it 'has tags' do
      expect(package.tags).to eq(['Аниме'])
    end

    describe '#structure' do
      it 'collects all atom types for question types' do
        suisei = package.structure
          .find { |r| r[:name] == 'Когда' }[:themes]
          .find { |t| t[:name] == 'Скрины' }[:questions]
          .find { |q| q[:answers] == ['Suisei no Gargantia'] }

        expect(suisei).to include(
          question_text: 'Назвать тайтл',
          question_types: ['text', 'image']
        )
      end
    end
  end

  context 'in Khardkor_po_Tolkinu.siq' do
    let(:file) { File.open(file_fixture('Khardkor_po_Tolkinu.siq')) }
    subject(:package) { described_class.new(file) }

    it 'rejects empty tag element' do
      expect(package.tags).to be_empty
    end
  end

  context 'in SIGameTest.siq' do
    let(:file) { File.open(file_fixture('SIGameTest.siq')) }
    subject(:package) { described_class.new(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end

    it 'has logo_width' do
      expect(package.logo_width).to eq(600)
    end

    it 'has logo_height' do
      expect(package.logo_height).to eq(600)
    end
  end

  context 'in packet_ot_stasyana_2.siq' do
    let(:file) { File.open(file_fixture('packet_ot_stasyana_2.siq')) }
    subject(:package) { described_class.new(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in 059_-_Treshovaya_solyanka_Novogodnyaya_-_Blacksmith_Remastered.siq' do
    let(:file) { File.open(file_fixture('059_-_Treshovaya_solyanka_Novogodnyaya_-_Blacksmith_Remastered.siq')) }
    subject(:package) { described_class.new(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in Meshanina_ot_Meladze_ch_9.siq' do
    let(:file) { File.open(file_fixture('Meshanina_ot_Meladze_ch_9.siq')) }
    subject(:package) { described_class.new(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in Lucifer_FM_2.siq' do
    let(:file) { File.open(file_fixture('Lucifer_FM_2.siq')) }
    subject(:package) { described_class.new(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in Sazha.siq' do
    let(:file) { File.open(file_fixture('Sazha.siq')) }
    subject(:package) { described_class.new(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end
end
