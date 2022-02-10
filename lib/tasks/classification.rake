namespace :classification do
  desc "Test classification"
  task cls: :environment do
    Rails.logger = Logger.new($stdout)

    c = Classification::Classifier.new('аниме')

    pp c.tag_tfidf.order(tfidf: :desc).limit(100).pluck(:lexeme, :tfidf).to_h
    # pp c.magn.order(magn: :asc).limit(100).pluck(:package_id, :magn).to_h
    # pp c.package_tfidf.where(package_id: 10169).as_json
    # pp c.package_len.where(package_id: 10169).as_json

    # pp c.package_lexemes.where(package_id: 10169).as_json

    puts 'done'
  end

  desc "Fill category_text for all packages"
  task fill_category_text: :environment do
    c = Classification::StringCleaner.new

    rel = Package.where.not(structure: nil).select(:id, :structure)

    batch_size = 100

    puts "Batching by #{batch_size}"

    rel.find_in_batches(batch_size:) do |batch|
      updates = {}

      batch.each do |package|
        updates[package.id] = {
          category_text: c.clean_string_from_package(package)
        }
      end

      Package.update!(updates.keys, updates.values)

      print '.'
    end

    puts "\nDone"
  end
end
