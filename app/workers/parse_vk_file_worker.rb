class ParseVkFileWorker
  include Sidekiq::Worker

  def perform(params)
    file_date = Time.at(params['file_date'])
    return if Package.skip_updating?(params['file_id'], file_date)

    url = params['file_url']

    logger.info "Parsing #{params['filename']} with url #{url}"
    begin
      resp = Net::HTTP.get_response(URI(url))
      url = resp['location']
      logger.info "Redirecting to #{url}"
    end while resp.is_a?(Net::HTTPRedirection)

    unless resp.is_a?(Net::HTTPOK)
      logger.info "HTTP result is #{resp.class.name}, skipping..."
      return
    end

    body = resp.body

    logger.info "Body length #{body.length}, parsing"

    begin
      si_package = Si::Package.new(body)
    rescue Zip::Error => e
      logger.info "Could not parse zip (#{e}), skipping..."
      return
    end

    name = si_package.name
    name = params['filename'] if name.blank?

    logger.info "Parsed, update_or_create! now"
    Package.update_or_create!(
      filename: params['filename'],
      name: name,
      authors: si_package.authors,
      source_link: params['source_link'],
      post_text: params['post_text'],
      published_at: file_date,
      structure: si_package.structure,
      tags: si_package.tags,
      vk_document_id: params['file_id'],
    )
  end
end
