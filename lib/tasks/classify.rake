namespace :classify do
  desc "Classify packages"
  task run: :environment do
    k = Classification::Classifier
    cls = k.new

    cls.prepare('anime')

    cls.predict

    pp cls.result
  end
end
