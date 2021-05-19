namespace :parse do
  desc "Parse packages from https://vk.com/topic-135725718_34975471"
  task vk_si_game: :environment do
    params = {
      group_id: 135725718,
      topic_id: 34975471,
      count: 100,
      offset: 0
    }

    result = Vk.board_get_comments(params)
    requests = 0
    while result.dig('response', 'items').present?
      requests += 1
      items = result.dig('response', 'items')
      puts "Parsing posts [#{params[:offset]}..#{params[:offset] + items.count}]"


      items.each do |i|
        next unless i['attachments']

        i['attachments'].each do |a|
          if a['type'] == 'doc' && a['doc']['title'].end_with?('.siq')
            doc = a['doc']

            p = Package.create!(
              name: doc['title'],
              source_link: "https://vk.com/topic-135725718_34975471?post=#{i['id']}"
            )
            puts "Created #{p.name}"
          end
        end
      end

      params[:offset] += items.count
      result = Vk.board_get_comments(params)
    end

    if requests == 0
      puts "First request failed?"
      pp result
    else
      puts "Done in #{requests} requests"
    end
  end

end
