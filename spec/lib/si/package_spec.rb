require 'rails_helper'

RSpec.describe Si::Package do
  def instance(name)
    described_class.new_from_xml_path(file_fixture(name))
  end

  describe '#authors' do
    it 'can parse single author' do
      expect(instance('content_a.xml').authors).to eq(['Author One'])
    end

    it 'can parse several authors with ampersands' do
      expect(instance('content_x.xml').authors).to eq(['Amper', 'Sand'])
    end
  end

  describe '#name' do
    it 'can parse name' do
      expect(instance('content_a.xml').name).to eq('Контент а')
    end
  end

  describe '#structure' do
    it 'can parse structure' do
      expect(instance('content_a.xml').structure).to eq [
        {
          name: '1-й раунд',
          themes: [
            {
              name: 'Темография',
              questions: [
                question_text: 'Какое слово я загадал?',
                answers: ['Вася'],
                question_types: ['text']
              ]
            },
            {
              name: 'С картинками',
              questions: [
                question_text: '',
                answers: ['Пикча'],
                question_types: ['image']
              ]
            }
          ]
        },
        {
          name: '2-й раунд',
          themes: [
            {
              name: 'Второй раунд первая тема',
              questions: []
            }
          ]
        }
      ]
    end

    it 'collects all atom types for question types' do
      expect(instance('content_x.xml').structure).to eq [
        name: 'Раунд!',
        themes: [
          name: 'Скрины',
          questions: [
            question_text: 'Назвать тайтл',
            question_types: ['text', 'image'],
            answers: ['Нарута']
          ]
        ]
      ]
    end
  end

  describe '#tags' do
    it "doesn't try to fix commas when has multiple tags" do
      expect(instance('content_x.xml').tags).to eq(['Аниме, Аниме 2', 'Другое'])
    end

    it 'tries to fix single tag with commas' do
      expect(instance('content_a.xml').tags).to eq(['Тег а', 'Тег б'])
    end

    it 'skips empty xml tags' do
      expect(instance('content_k.xml').tags).to be_empty
    end
  end

  describe '#split_tags' do
    it 'can split multiple tags from one string' do
      examples = {
        'doka 2' => ['doka 2'], # single tag stays single
        'Музыка, аниме' => %w[Музыка аниме],
        # inconsistent spacing
        'Игры, музыка, аниме,прикол,фильм' => %w[Игры музыка аниме прикол фильм],
        ',,,тег,,,,да' => %w[тег да] # no empty tags
      }

      examples.each do |from, to|
        expect(described_class.new.split_tags(from)).to eq(to)
      end
    end
  end

  context 'in SIGameTest.siq' do
    let(:file) { File.open(file_fixture('SIGameTest.siq')) }
    subject(:package) { described_class.new_from_siq_buffer(file) }

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
    subject(:package) { described_class.new_from_siq_buffer(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in 059_-_Treshovaya_solyanka_Novogodnyaya_-_Blacksmith_Remastered.siq' do
    let(:file) { File.open(file_fixture('059_-_Treshovaya_solyanka_Novogodnyaya_-_Blacksmith_Remastered.siq')) }
    subject(:package) { described_class.new_from_siq_buffer(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in Meshanina_ot_Meladze_ch_9.siq' do
    let(:file) { File.open(file_fixture('Meshanina_ot_Meladze_ch_9.siq')) }
    subject(:package) { described_class.new_from_siq_buffer(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in Lucifer_FM_2.siq' do
    let(:file) { File.open(file_fixture('Lucifer_FM_2.siq')) }
    subject(:package) { described_class.new_from_siq_buffer(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in Sazha.siq' do
    let(:file) { File.open(file_fixture('Sazha.siq')) }
    subject(:package) { described_class.new_from_siq_buffer(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end

  context 'in OxxxyFootball_2.siq' do
    let(:file) { File.open(file_fixture('OxxxyFootball_2.siq')) }
    subject(:package) { described_class.new_from_siq_buffer(file) }

    it 'has logo_bytes' do
      expect(package.logo_bytes).to be_present
    end
  end
end
