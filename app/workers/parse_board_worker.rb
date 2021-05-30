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
          next if Package.skip_updating?(doc['id'], Time.at(i['date']))

          ParseVkFileWorker.perform_async(
            filename: doc['title'],
            source_link: "https://vk.com/topic-#{group_id}_#{topic_id}?post=#{i['id']}",
            post_text: i['text'],
            file_url: doc['url'],
            file_date: i['date'],
            file_id: doc['id']
          )
        end
      end
    end
  end
end
