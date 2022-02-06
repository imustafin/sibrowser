namespace :classification do
  desc "Test classification"
  task cls: :environment do
    Rails.logger = Logger.new($stdout)

    c = Classification::Classifier.new('аниме')

    # pp c.tag_tfidf.order(tfidf: :asc).pluck(:lexeme, :tfidf).to_h
    # pp c.magn.order(magn: :asc).limit(100).pluck(:package_id, :magn).to_h
    # pp c.package_tfidf.where(package_id: 10169).as_json
    # pp c.package_len.where(package_id: 10169).as_json

    # pp c.package_lexemes.where(package_id: 10169).as_json

    puts 'done'
  end
end
