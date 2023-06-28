require 'rails_helper'

RSpec.describe CategoriesController do
  describe '#show' do
    it 'is ok for existing category' do
      get :show, params: { id: :videogames }
      expect(response).to have_http_status(:ok)
    end

    it 'redirects legacy category to new category if mapped' do
      get :show, params: { id: :gam }
      expect(response).to redirect_to('/categories/videogames')
    end

    it 'redirects to self without unused GET parameters' do
      get :show, params: {
        # used
        id: :meme,
        locale: :tt,
        sort: :download_count,
        only_pagination: true,
        # unused
        locacle: :en,
        direction: :asc
      }
      expect(response).to redirect_to(
        '/tt/categories/meme?only_pagination=true&sort=download_count'
      )
    end
  end
end
