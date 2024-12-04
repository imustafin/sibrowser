require 'net/http'

namespace :parse do
  desc "Parse packages from https://vk.com/topic-135725718_34975471"
  task vk_si_game: :environment do
    ParseBoardWorker.perform_async(135725718, 34975471)
  end

  desc "Parse packages from https://vk.com/topic-228528109_53000017"
  task vk_si_2: :environment do
    ParseBoardWorker.perform_async(228528109, 53000017)
  end

  desc "Parse one post by post id synchronously"
  task :vk_si_game_one, [:id] => :environment do |t, args|
    ParseBoardWorker.new.parse_one_post(135725718, 34975471, args[:id])
  end

  desc 'Delete all packages'
  task delete_packages: :environment do
    Package.delete_all
  end
end
