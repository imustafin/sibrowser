require 'rails_helper'

RSpec.describe Package, type: :model do
  describe '.update_or_create!' do
    context 'no existing' do
      it 'creates new' do
        expect {
          described_class.update_or_create!(
            vk_document_id: 1,
            name: 'qwe',
            source_link: 'qweqwe',
            version: described_class::VERSION
          )
        }
          .to change { described_class.count }.by(1)
      end
    end

    context 'with existing' do
      before(:each) do
        described_class.create(
          vk_document_id: 1,
          published_at: Time.at(10),
          post_text: 'original',
          name: 'qwe',
          source_link: 'qweqwe',
          version: described_class::VERSION
        )
      end

      it 'does not update if newer' do
        described_class.update_or_create!(
          vk_document_id: 1,
          published_at: Time.at(100),
          post_text: 'newer',
          name: 'qwe',
          source_link: 'qweqwe',
        )

        expect(described_class.find_by(vk_document_id: 1).post_text).to eq('original')
      end

      it 'updates if older' do
        described_class.update_or_create!(
          vk_document_id: 1,
          published_at: Time.at(1),
          post_text: 'older',
          name: 'qwe',
          source_link: 'qweqwe',
        )

        expect(described_class.find_by(vk_document_id: 1).post_text).to eq('older')
      end
    end
  end

  describe '#question_distribution' do
    it 'ignores types after marker' do
      p = build(:package_one_theme, questions: [{
        'question_types' => %w[text marker image voice video say]
      }])

      expect(p.question_distribution).to eq({
        total: 1,
        types: {
          text: 1
        }
      })
    end

    it 'takes the type of non-text atoms' do
      p = build(:package_one_theme, questions: [{
        'question_types' => %w[text text image text text text]
      }])

      expect(p.question_distribution).to eq({
        total: 1,
        types: {
          image: 1
        }
      })
    end

    it 'ignores "say"' do
      p = build(:package_one_theme, questions: [{
        'question_types' => %w[text text say say text say]
      }])

      expect(p.question_distribution).to eq({
        total: 1,
        types: {
          text: 1
        }
      })
    end

    it 'keeps gives :mixed if more than one of image-voice-video' do
      p = build(:package_one_theme, questions: [{
        'question_types' => %w[text text image voice video]
      }])

      expect(p.question_distribution).to eq({
        total: 1,
        types: {
          mixed: 1
        }
      })
    end
  end

  describe '.search_freetext' do
    it 'uses theme names' do
      p = create(:package_one_theme, theme: 'Яблоки')
      expect(described_class.search_freetext('яблоко')).to include(p)
    end

    it 'uses round names' do
      p = create(:package_one_theme, round: 'Бананы')
      expect(described_class.search_freetext('банан')).to include(p)
    end
  end
end
