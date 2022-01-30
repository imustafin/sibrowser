require 'rails_helper'

RSpec.describe Author do
  describe '.all' do
    it 'prefers titleized names' do
      create(:package, authors: ['ivan'])
      create(:package, authors: ['Ivan'])

      expect(described_class.all).to contain_exactly(
        have_attributes(
          author: 'Ivan'
        )
      )
    end

    it "doesn't have nil record for packages with downloads with no authors" do
      create(:package, authors: [], downloads: { '1' => 1 })

      expect(described_class.all).to be_empty
    end

    it 'has package counts' do
      create(:package, authors: ['ivan'])
      create(:package, authors: ['IVAN'])

      create(:package, authors: ['john'])

      expect(described_class.all).to contain_exactly(
        have_attributes(author: 'IVAN', count: 2),
        have_attributes(author: 'john', count: 1)
      )
    end

    it 'has total_downloads' do
      create(:package, authors: ['ivan'], downloads: { '1' => 1 })
      create(:package, authors: ['IVAN'], downloads: { '2' => 2 })

      create(:package, authors: ['john'], downloads: { '2' => 4 })

      create(:package, authors: [], downloads: { '1' => 8 })

      expect(described_class.all).to contain_exactly(
        have_attributes(author: 'IVAN', total_downloads: 3),
        have_attributes(author: 'john', total_downloads: 4)
      )
    end
  end
end
