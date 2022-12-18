namespace :classify do
  desc "Classify packages"
  task run: :environment do
    all_all = Package.where.not(structure: {})

    mapped = all_all.where.not(structure_classification: {})

    

    k = Classification::Classifier
    cls = k.new

    cls.prepare('anime')

    cls.predict

    pp cls.result
  end

  desc 'Show classification results on sample'
  task test: :environment do
    all = Package.where.not(structure: {})
    mapped = all.where.not(structure_classification: {})

    puts "All mapped: #{mapped.count}"

    test_ids = mapped.limit(mapped.count / 4).order('random()').pluck(:id)

    train = Package.from(all.where.not(id: test_ids), :packages)
    test = Package.from(all.where(id: test_ids), :packages)

    puts "Train on #{train.count} (mapped #{train.where.not(structure_classification: {}).count})"
    puts "Test on #{test.count}"

    k = Classification::Classifier.new
    k.train(train, 'anime')
    predicted = k.predict(test, true)

    matrix = {
      'yes' => { 'yes' => 0, 'no' => 0, 'null' => 0},
      'no' => { 'yes' => 0, 'no' => 0, 'null' => 0},
      'null' => { 'yes' => 0, 'no' => 0, 'null' => 0}
    }

    predicted.each do |row|
      id = row['id']
      y = row['cat']

      pid, *parts = id.split('_')
      k = [*parts, 'anime'].join('_')

      correct = Package.find(pid).structure_classification[k]

      matrix[correct][y] += 1
    end

    rows = []
    pp ['Predicted as ->', 'yes', 'no', 'null']
    matrix.each do |correct, v|
      pp [correct, v['yes'], v['no'], v['null']]
    end

  end
end
