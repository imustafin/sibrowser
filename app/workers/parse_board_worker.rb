class ParseBoardWorker
  include Sidekiq::Worker

  def perform(group_id, topic_id)
    params = {
      group_id: group_id,
      topic_id: topic_id,
      count: 100,
      offset: 0
    }

    loop do
      result = Vk.board_get_comments(params)
      items = result.dig('response', 'items')
      break if items.blank?

      params[:offset] += items.count

      items.each do |i|
        docs = (i['attachments'] || [])
         .filter { |a| a['type'] == 'doc' && a['doc']['title'].end_with?('.siq') }
         .map { |a| a['doc'] }

        docs.each do |doc|
          skip_updating = Package.skip_updating?(
            doc['id'],
            doc['owner_id'],
            Time.at(i['date'])
          )

          if skip_updating
            package = Package.find_by(
              vk_document_id: doc['id'],
              vk_owner_id: doc['owner_id']
            )

            if package
              package.touch_vk_download_url
              package.vk_download_url = doc['url']
              package.save!
            end

            next
          end

          ParseVkFileWorker.perform_async(
            'filename' => doc['title'],
            'source_link' => "https://vk.com/topic-#{group_id}_#{topic_id}?post=#{i['id']}",
            'post_text' => i['text'],
            'file_url' => doc['url'],
            'file_date' => i['date'],
            'file_id' => doc['id'],
            'owner_id' => doc['owner_id']
          )
        end
      end
    end
  end
end
