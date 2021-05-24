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
end
