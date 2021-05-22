class BoardParser
  def initialize(group_id, topic_id)
    @group_id = group_id
    @topic_id = topic_id
  end

  def parse_metas
    metas = {} # from file id to meta

    params = {
      group_id: @group_id,
      topic_id: @topic_id,
      count: 100,
      offset: 0
    }

    result = Vk.board_get_comments(params)
    while result.dig('response', 'items').present?
      items = result.dig('response', 'items')
      puts "Parsing posts [#{params[:offset]}..#{params[:offset] + items.count}]"

      items.each do |i|
        attachments = i['attachments']

        next unless attachments

        attachments.each do |a|
          next unless a['type'] == 'doc' && a['doc']['title'].end_with?('.siq')

          doc = a['doc']

          next if metas[doc['id']]

          metas[doc['id']] = {
            filename: doc['title'],
            source_link: "https://vk.com/topic-135725718_34975471?post=#{i['id']}",
            post_text: i['text'],
            file_url: doc['url'],
            file_date: Time.at(doc['date'])
          }
        end
      end

      params[:offset] += items.count
      result = Vk.board_get_comments(params)
    end

    metas
  end

  def parse_files(metas)
    num_threads = 4

    threads = metas.values.in_groups(num_threads, false).each_with_index.map do |batch, t|
      Thread.new do
        batch.each do |meta|
          url = meta[:file_url]

          puts "#{t}: Parsing #{meta[:filename]} with url"
          puts "#{t}:  #{url}"
          begin
            resp = Net::HTTP.get_response(URI(url))
            url = resp['location']
          end while resp.is_a?(Net::HTTPRedirection)

          unless resp.is_a?(Net::HTTPOK)
            puts "#{t}: HTTP result is #{resp.class.name}, skipping..."
            next
          end

          body = resp.body

          unless body.starts_with?("\x50\x4b\x03\x04")
            puts "#{t}: This doesn't look like zip, skipping..."
            next
          end

          si_package = Si::Package.read_from_siq(body)

          name = si_package.name
          name = meta[:filename] if name.blank?

          Package.create!(
            filename: meta[:filename],
            name: name,
            authors: si_package.authors,
            source_link: meta[:source_link],
            post_text: meta[:post_text],
            published_at: meta[:file_date]
          )
        end
      end
    end

    threads.each(&:join)
  end

  def parse!
    metas = parse_metas
    parse_files(metas)
  end
end
