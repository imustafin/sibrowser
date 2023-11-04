class ParseBoardWorker
  include Sidekiq::Worker

  def packages_with_post_extra_files(post_link, current_files)
    packages = Package.where(<<~SQL, params: { link: post_link }.to_json)
      jsonb_path_exists(posts,
        '$[*] ? (@.link == $link)',
        :params
      )
    SQL

    cf = current_files.map(&:symbolize_keys)
    packages.select do |p|
      by_link = p.posts.select { |post| post['link'] == post_link }
      by_link.any? do |p|
        dl = p.symbolize_keys.slice(:document_id, :owner_id)

        cf.exclude?(dl)
      end
    end
  end

  def remove_extra_downloads(packages, post_link, current_files)
    cf = current_files.map(&:symbolize_keys)

    packages.each do |package|
      package.with_lock do
        new_posts = package.posts.select do |p|
          # Keep other links
          p['link'] != post_link || \
            cf.include?(p.symbolize_keys.slice(:document_id, :owner_id))
        end

        if new_posts.empty?
          package.update!(
            posts: [],
            disappeared_at: Time.current
          )
        else
          package.update!(posts: new_posts)
        end
      end
    end
  end

  def post_for_message_doc(message:, doc:, post_link:)
    {
      'link' => post_link,
      'text' => message['text'],
      'document_id' => doc['id'],
      'owner_id' => doc['owner_id'],
      'published_at' => Time.at(message['date']).to_datetime.iso8601,
      'filename' => doc['title']
    }
  end

  def update_message_info(package:, message:, doc:, post_link:)
    package.with_lock do
      new_posts = package.posts.map do |p|
        this = p['link'] == post_link \
          && p['document_id'] == doc['id'] \
          && p['owner_id'] == doc['owner_id']

        next p unless this

        post_for_message_doc(message:, doc:, post_link:)
      end

      package.update!(
        posts: new_posts,
        vk_download_url: doc['url'],
        vk_download_url_updated_at: Time.current
      )
    end
  end

  def perform(group_id, topic_id)
    parsing_timestamp = Time.current.iso8601

    params = {
      group_id: group_id,
      topic_id: topic_id,
      count: 100,
      offset: 0
    }

    loop do
      logger.info "Parsing offest #{params[:offset]}"
      result = Vk.board_get_comments(params)
      items = result.dig('response', 'items')
      break if items.blank?

      params[:offset] += items.count

      items.each do |i|
        process_post(i, group_id:, topic_id:, parsing_timestamp:, async: true)
      end
    end
  end

  # Used only for rake task
  def parse_one_post(group_id, topic_id, start_comment_id)
    parsing_timestamp = Time.current.iso8601

    params = { count: 1, group_id:, topic_id:, start_comment_id: }

    result = Vk.board_get_comments(params)
    items = result.dig('response', 'items')
    if items.blank?
      puts 'No posts returned'
      return
    end

    items.each do |i|
      puts "Parsing post"
      process_post(i, group_id:, topic_id:, parsing_timestamp:, async: false)
    end
  end

  def parse_file(doc, default_post:, parsing_timestamp:, published_at:, async:)
    params = {
      'document_id' => doc['id'],
      'owner_id' => doc['owner_id'],
      'url' => doc['url'],
      'default_post' => default_post,
      'parsing_timestamp' => parsing_timestamp,
      'published_at' => published_at,
      'filename' => doc['title']
    }

    if async
      ParseVkFileWorker.perform_async(**params)
    else
      ParseVkFileWorker.new.perform(**params)
    end
  end

  def process_post(message, group_id:, topic_id:, parsing_timestamp:, async:)
    docs = (message['attachments'] || [])
      .filter { |a| a['type'] == 'doc' && a['doc']['title'].end_with?('.siq') }
      .map { |a| a['doc'] }

    # attachment disappeared case
    post_link = "https://vk.com/topic-#{group_id}_#{topic_id}?post=#{message['id']}"
    current_files = docs.map { |x| { document_id: x['id'], owner_id: x['owner_id'] } }
    # In packages which have this post and some extra vk document
    where_disappeared = packages_with_post_extra_files(post_link, current_files)
    # ... remove this extra vk document
    remove_extra_downloads(where_disappeared, post_link, current_files)

    docs.each do |doc|
      # attachment appeared
      where_exists = ParseUtils.packages_for_doc(
        document_id: doc['id'],
        owner_id: doc['owner_id']
      )

      if where_exists.exists?
        # We already have package for this file
        # Assuming doc_owner always gives same file (by hash)
        # so there is only one package for this vk doc
        package = where_exists.first

        update_message_info(package:, message:, doc:, post_link:)

        if package.version < Package::VERSION
          parse_file(
            doc,
            async:,
            default_post: nil,
            parsing_timestamp:,
            published_at: Time.at(message['date']).to_datetime.iso8601
          )
        end
      else
        default_post = post_for_message_doc(
          message:,
          doc:,
          post_link:
        )
        parse_file(
          doc,
          async:,
          default_post:,
          parsing_timestamp:,
          published_at: Time.at(message['date']).to_datetime.iso8601
        )
      end
    end
  end
end
