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

  def self.has_tokens?
    app_id && secret && service
  end

  def self.base_configs
    {
      access_token: service,
      v: '5.131',
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

  def self.groups_get_by_id(params)
    request('groups.getById', params)
  end

  # Returns uri to retry
  #
  # https://github.com/yt-dlp/yt-dlp/issues/3797#issuecomment-1170071123
  def self.retry_handle_429(response, desired_uri)
    location = response['location']

    vk = URI('https://vk.com')
    x = URI.join(vk, location)

    queries = CGI.parse(x.query).to_h { |k, v| [k, v.first] }
    digest = Digest::MD5.hexdigest(queries['hash429'])

    queries['key'] = digest
    x.query = queries.to_query

    last_response = Net::HTTP.get_response(x)

    raise 'Vk 429 not success' if last_response['x-challenge'] != 'success'
    s429 = CGI.parse(URI.join(vk, last_response['location']).query)['s429'].first

    URI("#{desired_uri}&s429=#{s429}")
  end

  def self.response_requires_429?(response)
    response['x-challenge'] == 'required'
  end
end
