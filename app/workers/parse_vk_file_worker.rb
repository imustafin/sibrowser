class ParseVkFileWorker
  include Sidekiq::Worker

  class UnknownVkError < StandardError
  end

  def download_vk(url)
    redirects_finished = false

    tempfile = nil

    uri = URI(url)
    download_done = false
    until download_done
      Net::HTTP.get_response(uri) do |resp|
        if Vk.response_requires_429?(resp)
          uri = Vk.retry_handle_429(resp, uri)
        elsif resp.is_a?(Net::HTTPRedirection)
          # Normal redirect
          location = resp['location']
          uri = if location.start_with?('/')
            URI.join(uri, location)
          else
            URI(location)
          end
        elsif resp.is_a?(Net::HTTPOK)
          tempfile = Tempfile.new(['package', '.siq'], binmode: true)
          resp.read_body(tempfile)
          tempfile.rewind
          download_done = true
        else
          logger.info "HTTP result is #{resp.class.name}, skipping"
          download_done = true
        end
      end
    end

    tempfile
  end

  def vk_error?(file)
    start = file.read(50)
    file.rewind

    return false unless ['<!DOCTYPE html>', '  <!DOCTYPE html>'].any? { |s| start.start_with?(s) }

    doc = Nokogiri::HTML(file)

    error_body = doc.xpath('//div[@class="message_page_body"]/text()').first&.text&.squish

    messages = [
      'Файл недоступен или удалён',
      'This file is unavailable or has been deleted',
      'Tài liệu không có sẵn hoặc bị xóa', # vn

      'Пользователь, который загрузил файл, заблокирован.',
      'The owner of this file has been blocked.'
    ]

    raise UnknownVkError, error_body if messages.exclude?(error_body)

    error_body
  end

  def clean_url(url)
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query).to_h.slice('hash')
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def compute_hash(file)
    h = Digest::SHA512.new

    file.each(nil, 512) do |chunk|
      h << chunk
    end

    file.rewind

    h.hexdigest
  end

  def perform(params)
    document_id = params['document_id']
    owner_id = params['owner_id']
    url = params['url']
    default_post = params['default_post']
    parsing_timestamp = params['parsing_timestamp'].to_datetime
    published_at = params['published_at']

    existing = ParseUtils.packages_for_doc(document_id:, owner_id:).first

    if existing \
        && existing.parsed_at > parsing_timestamp \
        && existing.version >= Package::VERSION
      # Package is fresh and already parsed after the requested time,
      # so skip
      return
    end

    vk_download_url = clean_url(url)

    logger.info "Parsing url #{url} (#{document_id} by #{owner_id})"

    siq = download_vk(url)

    if !siq || (vk_error = vk_error?(siq))
      if existing
        # Remove post
        existing.with_lock do
          new_posts = existing.posts.reject do |p|
            p['document_id'] == document_id && p['owner_id'] == owner_id
          end

          if new_posts.empty?
            existing.update!(
              posts: [],
              disappeared_at: Time.current,
              parsed_at: Time.current
            )
          else
            existing.update!(
              posts: new_posts,
              parsed_at: Time.current
            )
          end
        end
      end

      logger.info "Vk file unavailable (vk error #{vk_error || '<nil>'})"

      return
    end

    file_size = siq.length

    file_hash = compute_hash(siq)

    logger.info "Body length #{file_size}, parsing"

    begin
      si_package = Si::Package.new_from_siq_buffer(siq)
    rescue Zip::Error => e
      if e.message == 'Zip end of central directory signature not found'
        logger.info "Siq zip file error: #{e.message}"
        return
      end

      raise
    end

    name = si_package.name
    name = params['filename'] if name.blank?

    logger.info "Parsed"

    package_params = {
      name: name,
      authors: si_package.authors,
      published_at: published_at,
      structure: si_package.structure,
      tags: si_package.tags,
      disappeared_at: nil,
      vk_download_url:,
      vk_download_url_updated_at: Time.current,
      file_size:,
      logo_bytes: si_package.logo_bytes,
      logo_width: si_package.logo_width,
      logo_height: si_package.logo_height,
      file_hash:,
      parsed_at: Time.current
    }
    package_params[:posts] = [default_post] if default_post
    Package.update_or_create!(**package_params)

    siq.close!
  end
end
