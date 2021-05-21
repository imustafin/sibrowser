require 'net/http'

namespace :parse do
  desc "Parse packages from https://vk.com/topic-135725718_34975471"
  task vk_si_game: :environment do
    BoardParser.new(135725718, 34975471).parse!
  end

  desc 'Delete all packages'
  task delete_packages: :environment do
    Package.delete_all
  end

end
