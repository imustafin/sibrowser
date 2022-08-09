namespace :classify do
  desc "Classify packages"
  task run: :environment do
    k = Classification::Classifier
    cls = k.new

    cls.prepare

    pp k::Termprob.limit(10).as_json
  end
end
