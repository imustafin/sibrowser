require 'net/http'

namespace :parse do
  desc "Parse packages from https://vk.com/topic-135725718_34975471"
  task vk_si_game: :environment do
    ParseBoardWorker.perform_async(135725718, 34975471)
  end

  desc 'Delete all packages'
  task delete_packages: :environment do
    Package.delete_all
  end
end
