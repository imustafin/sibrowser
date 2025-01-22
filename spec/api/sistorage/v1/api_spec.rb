require 'rails_helper'

RSpec.describe Sistorage::V1::Api do
  describe 'GET /packages/search' do
    describe 'pagination' do
      it 'uses from as offset' do
        a = create(:package)
        b = create(:package)
        c = create(:package)
        d = create(:package)

        get '/sistorage/api/v1/packages/search', params: { count: 2 }
        expect(response).to be_successful
        res = response.parsed_body
        expect(res['packages'].count).to eq(2)
        expect(res['packages'].pluck('id')).to contain_exactly(a.id, b.id)

        get '/sistorage/api/v1/packages/search', params: { count: 2, from: 2 }
        expect(response).to be_successful
        res = response.parsed_body
        expect(res['packages'].count).to eq(2)
        expect(res['packages'].pluck('id')).to contain_exactly(c.id, d.id)
      end
    end
  end
end
