require 'rails_helper'

RSpec.describe ParseUtils do
  describe '#packages_for_doc' do
    it 'has only packages with this doc and outdated version' do
      this = {
        'document_id' => 'this_id',
        'owner_id' => 'this_owner'
      }
      other = {
        'document_id' => 'other_id',
        'owner_id' => 'other_owner'
      }
      matching = create(:package, posts: [this, other])
      non_matching = create(:package, posts: [other])

      expect(described_class.packages_for_doc(
        document_id: 'this_id', owner_id: 'this_owner'
      )).to contain_exactly(matching)
    end
  end
end
