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

  describe 'js' do
    describe '.js_func' do
      it 'handles simple returns' do
        expect(described_class.js_func('return -13')).to eq(-13)
      end

      it 'handles subtraction' do
        expect(described_class.js_func('return e - 1', 10)).to eq(9)
      end

      it 'handles xor' do
        expect(described_class.js_func('return e ^ 2', 10)).to eq(8)
      end

      it 'handles nil xor' do
        expect(described_class.js_func('return e ^ 3', nil)).to eq(3)
      end

      it 'handles map access' do
        expect(
          described_class.js_func('var map = {"-1":1,"-2":2};return map[e]', -2))
            .to eq(2)
      end
    end
  end
end
