require 'net/http'

module Vk
  def self.app_id
    Rails.configuration.x.vk_app_id
  end

  def self.secret
    Rails.configuration.x.vk_secret
  end

  def self.service
    Rails.configuration.x.vk_service
  end

  def self.base_configs
    {
      access_token: service,
      v: '5.130',
    }
  end

  def self.request(method, params)
    uri = URI("https://api.vk.com/method/#{method}")
    uri.query = URI.encode_www_form(base_configs.merge(params))

    res = Net::HTTP.get_response(uri)

    JSON.parse(res.body)
  end

  def self.board_get_comments(params)
    request('board.getComments', params)
  end
end
