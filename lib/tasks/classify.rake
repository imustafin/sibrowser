namespace :classify do
  desc "Classify packages"
  task run: :environment do
    all_all = Package.where.not(structure: {})

    mapped = all_all.where.not(structure_classification: {})

    k = Classification::Classifier.new
    k.train(mapped, 'anime')

    of = 200
    i = 0
    all_all.in_batches(of:) do |batch|
      puts "Saving predictions #{i}/#{all_all.count / of}"
      i += 1

      prediction = k.predict(batch, false)

      Package.connection.execute(<<~SQL.squish)
        update #{Package.table_name} as p
        set cat_anime_ratio = y.match_part
        from (#{prediction.to_sql}) as y
        where p.id = y.id
      SQL
    end
  end

  desc 'Show classification results on sample'
  task test: :environment do
    results = {}

    SibrowserConfig::CATEGORIES_2.each do |cat|
      all = Package.where.not(structure: {})
      mapped = all
        .where.not(structure_classification: {})
        .select do |p| # should have at least one for this cat
          p.structure_classification.any? do |k, v|
            # this can and not null mapping
            k.split('_').last == cat.to_s \
              && v != 'null'
          end
        end

      mapped_rel = all.where(id: mapped.pluck(:id))

      results[cat] = Classification::Evaluator.new.repeated_k_fold(mapped_rel, 1, 5, cat)
    end

    pp results
  end
end
