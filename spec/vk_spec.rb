require 'rails_helper'

RSpec.describe Vk do
  describe '.board_get_comments' do
    it 'loads comments' do
      pending('no vk token') unless described_class.has_tokens?

      expect(
        described_class.board_get_comments({
          group_id: 1,
          topic_id: 21972169,
          count: 1
        })
      ).to match_array({
        'response' => {
          'count' => 3741,
          'items' => [
            include({
              'id' => 11376,
              'text' => start_with('Тема закрыта')
            })
          ]
        }
      })
    end
  end

  describe '.groups_get_by_id' do
    it 'loads member_count field' do
      pending('no vk token') unless described_class.has_tokens?

      expect(
        described_class.groups_get_by_id({
          group_id: 'sibrowser',
          fields: 'members_count'
        })
      ).to match_array({
        'response' => [
          include({
            'id' => 204752566,
            'members_count' => be > 0
          })
        ]
      })
    end
  end
end
