require 'rails_helper'

RSpec.describe Si::Package do
  describe '.read_from_siq' do
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
        '1-й раунд' => [
          'География',
          'Советские актеры',
          'Юмористы',
          'Логотипы',
          'ПК',
          'Машины'
        ],
        '2-й раунд' => [
          'Зарубежные актеры',
          'Зарубежные певцы',
          'Зарубежные фильмы',
          'Репчага русская',
          'Родненькие)',
          'Категория для Sveta!!!',
        ],
        '3-й раунд' => [
          'История',
          'Еда',
          'Телешоу',
          'Спорт',
          'Зашквар такое знать!',
        ],
        'ФИНАЛ' => [
          'Для Светы',
          'Велоспорт',
          'Шахматы',
          '10000IQ',
          'Железные птицы',
          'Кто на фото',
          'Инструмент дело такое',
        ]
      )
    end
  end
end
