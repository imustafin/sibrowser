require 'rails_helper'

RSpec.describe Sistorage::V1::Api do
  describe 'GET /packages/search' do
    def do_search(**params)
      get '/sistorage/api/v1/packages/search', params: params
      expect(response).to be_successful
      response.parsed_body
    end

    describe 'pagination' do
      it 'uses from as offset' do
        a = create(:package)
        b = create(:package)
        c = create(:package)
        d = create(:package)

        res = do_search(count: 2)
        expect(res['packages'].count).to eq(2)
        expect(res['packages'].pluck('id')).to contain_exactly(a.id, b.id)

        res = do_search(count: 2, from: 2)
        expect(res['packages'].count).to eq(2)
        expect(res['packages'].pluck('id')).to contain_exactly(c.id, d.id)
      end
    end

    describe 'sort' do
      it 'sorts by id by default' do
        [-100, -10, -15, -20, -30].each { create(:package, id: it) }

        res = do_search
        expect(res['packages'].pluck('id')).to eq([-100, -30, -20, -15, -10])
      end

      it 'can sort by name' do
        ['x','a', 'b'].each { create(:package, name: it) }

        res = do_search(sortMode: 0)
        expect(res['packages'].pluck('name')).to eq(['a', 'b', 'x'])
      end

      it 'can sort by creation date' do
        old = create(:package, created_at: Time.new(2020))
        older = create(:package, created_at: Time.new(2019))
        newer = create(:package, created_at: Time.new(2021))

        res = do_search(sortMode: 1)
        expect(res['packages'].pluck('id')).to eq([older.id, old.id, newer.id])
      end

      it 'can sort by download count' do
        a = create(:package, downloads: { '1' => 0 })
        b = create(:package, downloads: { '1' => 10 })
        c = create(:package, downloads: { '1' => 5 })

        res = do_search(sortMode: 2)
        expect(res['packages'].pluck('id')).to eq([a.id, c.id, b.id])
      end

      it 'can sort in both directions' do
        [-100, -10, -15].each { create(:package, id: it) }

        res = do_search(sortDirection: 0)
        expect(res['packages'].pluck('id')).to eq([-100, -15, -10])

        res = do_search(sortDirection: 1)
        expect(res['packages'].pluck('id')).to eq([-10, -15, -100])
      end
    end
  end
end
