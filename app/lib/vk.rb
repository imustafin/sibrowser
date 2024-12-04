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

    challenge = Net::HTTP.get_response(x)

    queries = CGI.parse(x.query).to_h { |k, v| [k, v.first] }
    hash429 = queries['hash429']
    salt = challenge.body.match(/salt = ([^\n]*)/)&.captures&.[](0)
    salt = parse_salt(salt)
    data = hash429
    data += ':' + salt if salt
    digest = Digest::MD5.hexdigest(data)

    queries['key'] = digest
    x.query = queries.to_query

    challenge_response = Net::HTTP.get_response(x)

    raise 'Vk 429 not success' if challenge_response['x-challenge'] != 'success'
    cookie = challenge_response['set-cookie']
    location = URI.join(vk, challenge_response['location'])

    [location, cookie]
  end

  def self.parse_salt(s)
    if data = /^'(.*)'$/.match(s)
      return data.captures[0]
    end

    return unless s.starts_with?('(function() {') && s.ends_with?(';})();')
    s = s.delete_prefix('(function() {')
    s = s.delete_suffix(';})();')

    codes = s.delete_prefix('var codes = [[').split(']];').first.split('],[')
    codes = codes.map do |carr|
      carr
        .split(/\(function\(e?\) ?{/)
        .reject(&:blank?)
        .map { |s| s.delete_suffix(',').delete_suffix(';})') }
        .reverse
    end


    nums = codes.map do |cod|
      cod
        .reduce(0) { |code, f| js_func(f, code) }
        .chr
    end

    nums.join
  end

  def self.js_func(s, arg = nil)
    if s.start_with?('return')
      s = s.delete_prefix('return ')
      if s.match?(/^-?\d+$/)
        return s.to_i
      end
      matches = /.* (.) (.*)/.match(s)
      r = matches[2].to_i
      op = matches[1]
      if op == '-'
        return arg.to_i - r
      elsif op == '+'
        return arg.to_i + r
      elsif op == '^'
        if arg
          return arg.to_i ^ r
        else
          r
        end
      end
    elsif s.start_with?('var map = {')
      s = s.delete_prefix('var map = {')
      m = s.split('};return').first.split(',')
      m.each do |s|
        k, v = s.split(':')
        if k == "\"#{arg}\""
          return v.to_i
        end
      end
      return nil
    else
      raise "Unknown function #{s}"
    end
  end

  def self.response_requires_429?(response)
    response['x-challenge'] == 'required'
  end
end
