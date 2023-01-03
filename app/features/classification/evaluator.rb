module Classification
  class Evaluator
    # All packages should be mapped
    def repeated_k_fold(packages, n, k)
      matrix = Array
        .new(n) { k_fold(packages, k) }
        .reduce(&method(:sum_m))

      {
        matrix:,
        metrics: metrics(matrix)
      }
    end

    def k_fold(packages, k)
      ids = packages.pluck(:id)

      train_sets = ids
        .shuffle
        .in_groups_of(ids.count / k, false)

      train_sets
        .map { |test_ids| evaluate(packages.where.not(id: test_ids),
                                    packages.where(id: test_ids)) }
        .reduce(&method(:sum_m))
    end

    def evaluate(train, test)
      k = Classification::Classifier.new
      k.train(train, 'anime')
      predicted = k.predict(test, true)

      matrix = {
        'yes' => { 'yes' => 0, 'no' => 0 },
        'no' => { 'yes' => 0, 'no' => 0 }
      }

      predicted.each do |row|
        id = row['id']
        y = row['cat']

        pid, *parts = id.split('_')
        k = [*parts, 'anime'].join('_')

        correct = Package.find(pid).structure_classification[k]

        next if correct == 'null'

        matrix[correct][y] += 1
      end

      matrix
    end

    def predict(train, x)
      k = Classification::Classifier.new
      k.train(train, 'anime')
      predicted = k.predict(x, false)

      predicted
    end

    def sum_m(a, b)
      ans = a.deep_dup

      kk = ['yes', 'no']
      kk.each do |x|
        kk.each do |y|
          ans[x][y] += b[x][y]
        end
      end

      ans
    end

    def metrics(matrix)
      tp = matrix['yes']['yes']
      fn = matrix['yes']['no']
      fp = matrix['no']['yes']
      tn = matrix['no']['no']

      precision = tp.fdiv(tp + fp)
      recall = tp.fdiv(tp + fn)
      f1 = (2 * (precision * recall)).fdiv(precision + recall)
      {
        precision:,
        recall:,
        f1:
      }
    end
  end
end
