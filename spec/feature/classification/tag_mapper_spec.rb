require 'rails_helper'

RSpec.describe Classification::TagMapper do
  def cp(tags)
    create(:package, tags:)
  end

  describe '#tag_mapped' do
    it 'has category weight' do
      id = cp(['аниме', 'anime', 'music', 'unk???']).id
      instance = described_class.new

      expect(instance.tag_mapped.all).to contain_exactly(
        have_attributes(
          id:,
          category: 'anime',
          weight: be_within(0.001).of(2.0 / 4)
        ),
        have_attributes(
          id:,
          category: 'music',
          weight: be_within(0.001).of(1.0 / 4)
        )
      )
    end
  end
end
