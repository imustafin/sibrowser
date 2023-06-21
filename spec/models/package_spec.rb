require 'rails_helper'

RSpec.describe Package, type: :model do
  describe '.update_or_create!' do
    context 'no existing' do
      it 'creates new' do
        expect {
          described_class.update_or_create!(
            file_hash: '1',
            name: 'qwe',
            parsed_at: Time.current,
            version: described_class::VERSION
          )
        }
          .to change { described_class.count }.by(1)
      end
    end

    context 'with existing' do

      it 'updates existing by hash' do
        base_params = {
          parsed_at: Time.current,
          name: 'original',
          file_hash: '1'
        }

        base = create(:package_one_theme,
          **base_params, published_at: Time.zone.at(10))

        described_class.update_or_create!(
          **base_params,
          published_at: Time.zone.at(1),
          name: 'older',
        )

        expect(base.reload.name).to eq('older')
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
          text: 1,
          image: 0,
          video: 0,
          voice: 0
        }
      })
    end

    it 'treats "say" as "text"' do
      p = build(:package_one_theme, questions: [{
        'question_types' => %w[say]
      }])

      expect(p.question_distribution).to eq({
        total: 1,
        types: {
          text: 1,
          image: 0,
          video: 0,
          voice: 0
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

  describe '#add_download' do
    it 'adds new key if no downloads today', :aggregate_failures do
      p = create(:package, downloads: { '1' => 10 })

      travel_to Time.zone.local(2022, 1, 25, 23, 12) do
        expect { p.add_download; p.save! }
          .to change { p.download_count }.from(10).to(11)

        expect(p.downloads).to match_array({
          '1' => 10,
          '19017' => 1
        })
      end
    end
  end

  describe '#download_count' do
    it 'gives 0 for empty downloads' do
      p = create(:package)

      expect(p.download_count).to be 0
    end

    it 'gives sum of downloads' do
      p = create(:package, downloads: { '1' => 1, '2' => 20 })

      expect(p.download_count).to be 21
    end
  end

  describe '.download_stats' do
    it 'gives year, month, week, day download counts' do
      travel_to Time.zone.local(2022, 2, 8) do
        p = create(:package, downloads: {
          '19031' => 1,  # Tue, 08 Feb 2022  <- today
          '19030' => 2,  # Mon, 07 Feb 2022 ^- this week
          '19029' => 4,  # Sun, 06 Feb 2022
          '19024' => 8,  # Tue, 01 Feb 2022 ^- this month
          '19023' => 16, # Mon, 31 Jan 2022
          '18993' => 32, # Sat, 01 Jan 2022 ^- this year
          '18992' => 64 # Fri, 31 Dec 2021
        })

        expect(described_class.download_stats).to match_array({
          day: 1,
          week: 1 + 2,
          month: 1 + 2 + 4 + 8,
          year: 1 + 2 + 4 + 8 + 16 + 32,
          total: 1 + 2 + 4 + 8 + 16 + 32 + 64
        })
      end
    end

    it 'gives all zeros if no packages' do
      expect(described_class.download_stats).to match_array({
        day: 0,
        week: 0,
        month: 0,
        year: 0,
        total: 0
      })
    end
  end

  describe '.download_counts', focus: true do
    it 'aggregates downloads per day' do

      create(:package, downloads: { '0' => 1 })
      create(:package, downloads: { '0' => 2 })
      create(:package, downloads: { '1' => 4 })
      create(:package, downloads: { '2' => 8 })

      expect(Package.all.download_counts).to contain_exactly(
        have_attributes(date: Date.new(1970, 1, 1), count: 3),
        have_attributes(date: Date.new(1970, 1, 2), count: 4),
        have_attributes(date: Date.new(1970, 1, 3), count: 8)
      )
    end

    it 'can by date after' do
      create(:package, downloads: { '1' => 1 })
      create(:package, downloads: { '9' => 1 })

      expect(Package.all.download_counts.where('date = ?', Date.new(1970, 1, 10)))
        .to contain_exactly(
          have_attributes(date: Date.new(1970, 1, 10), count: 1)
        )
    end

    it 'can filter by packages first' do
      a = create(:package, downloads: { '0' => 1 })
      b = create(:package, downloads: { '1' => 2 })

      expect(Package.where(id: a.id).download_counts).to contain_exactly(
        have_attributes(date: Date.new(1970, 1, 1), count: 1)
      )
    end

    it 'is empty when no downloads' do
      expect(Package.download_counts).to be_empty
    end

    it 'has correct today date' do
      travel_to Time.zone.local(2022, 1, 31, 0, 11) do
        p = create(:package)
        p.add_download
        p.save!

        expect(Package.where(id: p.id).download_counts).to contain_exactly(
          have_attributes(date: Date.new(2022, 1, 31), count: 1)
        )
      end

    end
  end
end
