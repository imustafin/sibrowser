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

    describe 'filter' do
      it 'can search by text' do
        a = create(:package, name: 'apple juice')
        _b = create(:package, name: 'apple pie')
        c = create(:package, name: 'orange juice')

        res = do_search(searchText: 'juice')
        expect(res['packages'].pluck('id')).to contain_exactly(a.id, c.id)
      end

      it 'can search by tags' do
        a = create(:package, tags: ['apple', 'juice'])
        b = create(:package, tags: ['apple', 'pie'])
        c = create(:package, tags: ['orange', 'juice'])

        res = do_search(tags: 'apple')
        expect(res['packages'].pluck('id')).to contain_exactly(a.id, b.id)

        res = do_search(tags: 'orange,juice')
        expect(res['packages'].pluck('id')).to contain_exactly(c.id)
      end
    end
  end

  describe 'GET /packages/:id' do
    describe 'logoUri' do
      it 'has logo path or nil' do
        a = create(:package, logo_bytes: 1)
        b = create(:package)

        get "/sistorage/api/v1/packages/#{a.id}"
        expect(response).to be_successful
        expect(response.parsed_body['logoUri']).to eq "/packages/#{a.id}/logo.webp"

        get "/sistorage/api/v1/packages/#{b.id}"
        expect(response).to be_successful
        expect(response.parsed_body['logoUri']).to be_nil
      end
    end
  end

  describe 'GET /facets/tags' do
    it 'returns tags in alphabetical order without duplicates' do
      create(:package, tags: ['Aone', 'Btwo'])
      create(:package, tags: ['Btwo', 'Cthree'])

      get '/sistorage/api/v1/facets/tags'
      expect(response).to be_successful
      res = response.parsed_body
      expect(res.pluck('name')).to eq(['Aone', 'Btwo', 'Cthree'])
    end
  end
end
