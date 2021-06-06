class ParseVkFileWorker
  include Sidekiq::Worker

  def download_vk(url)
    redirects_finished = false

    until redirects_finished
      Net::HTTP.get_response(URI(url)) do |resp|
        if resp.is_a?(Net::HTTPRedirection)
          url = resp['location']
        else
          redirects_finished = true
        end
      end
    end

    tempfile = Tempfile.new(['package', '.siq'], binmode: true)

    Net::HTTP.get_response(URI(url)) do |resp|
      raise "HTTP result is #{resp.class.name}, not ok" unless resp.is_a?(Net::HTTPOK)
      resp.read_body(tempfile)
    end

    tempfile
  end


  def perform(params)
    file_date = Time.at(params['file_date'])
    return if Package.skip_updating?(params['file_id'], file_date)

    url = params['file_url']

    logger.info "Parsing #{params['filename']} with url #{url}"

    siq = download_vk(url)

    logger.info "Body length #{siq.length}, parsing"

    si_package = Si::Package.new(siq)

    name = si_package.name
    name = params['filename'] if name.blank?

    logger.info "Parsed"

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

    siq.close!
  end
end
