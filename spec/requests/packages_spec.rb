require 'rails_helper'

RSpec.describe "Packages", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/packages/index"
      expect(response).to have_http_status(:success)
    end
  end

end
