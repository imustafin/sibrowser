require 'rails_helper'

RSpec.describe ParseBoardWorker do
  subject(:instance) { described_class.new }

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

      expect(instance.packages_for_doc(doc_id: 'this_id', owner_id: 'this_owner'))
        .to contain_exactly(matching)
    end
  end

  describe '#packages_with_post_extra_files' do
    it 'has only packages with this post link and docs not present in current_files' do
      # This is in current_files
      present = { 'document_id' => 'a', 'owner_id' => 'a' }
      # This is not in current_files
      missing = { 'document_id' => 'z', 'owner_id' => 'z' }
      this = { 'link' => 't' }
      other = { 'link' => 'o' }

      present_this = create(:package, posts: [**present, **this])
      present_other = create(:package, posts: [**present, **other])
      missing_this = create(:package, posts: [**missing, **this])
      missing_other = create(:package, posts: [**missing, **other])

      expect(instance.packages_with_post_extra_files(this['link'], [present]))
        .to contain_exactly(missing_this)
    end
  end

  describe '#remove_extra_downloads' do
    it 'removes only posts with this link and files not in array' do
      # This is in current_files
      present = { 'document_id' => 'a', 'owner_id' => 'a' }
      # This is not in current_files
      missing = { 'document_id' => 'z', 'owner_id' => 'z' }
      this = { 'link' => 't' }
      other = { 'link' => 'o' }

      present_this = create(:package, posts: [**present, **this])
      present_other = create(:package, posts: [**present, **other])
      missing_this = create(:package, posts: [**missing, **this])
      missing_other = create(:package, posts: [**missing, **other])
      all = [present_this, present_other, missing_this, missing_other]

      instance.remove_extra_downloads(all, 't', [present])

      all.each(&:reload)

      expect(present_this.posts).to eq([**present, **this])
      expect(present_other.posts).to eq([**present, **other])
      expect(missing_this.posts).to eq([])
      expect(missing_other.posts).to eq([**missing, **other])
    end
  end

  describe '#update_message_info' do
    it 'updates only relevant post with needed info' do
      irrelevant_post = {
        'link' => 'this link',
        'document_id' => 'other id',
        'owner_id' => 'other owner',
        'text' => 'old text'
      }
      old_posts = [
        irrelevant_post,
        {
          'link' => 'this link',
          'document_id' => 'this id',
          'owner_id' => 'this owner'
        }
      ]
      date = Time.current.iso8601
      message = {
        'text' => 'new text',
        'date' => date
      }
      doc = {
        'owner_id' => 'this owner',
        'id' => 'this id',
        'url' => 'new url',
        'title' => 'new filename',
      }
      p = create(:package, posts: old_posts)

      instance.update_message_info(package: p, message:, doc:, post_link: 'this link')

      expect(p.reload).to have_attributes(
        posts: [
          irrelevant_post,
          {
            'link' => 'this link',
            'document_id' => 'this id',
            'owner_id' => 'this owner',
            'text' => 'new text',
            'filename' => 'new filename',
            'published_at' => date
          }
        ],
        vk_download_url: 'new url'
      )
    end
  end
end
