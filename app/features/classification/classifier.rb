module Classification
  class Classifier
    attr_accessor :tid, :cat

    def model(name, **cols, &blk)
      self.class.attr_accessor(name)

      tablename = "#{name}_#{tid}"

      execute <<~SQL
        create temporary table #{tablename}
        (
          #{cols.map { |k, v| "#{k} #{v}" }.join(', ')}
        );
      SQL

      instance_variable_set(
        "@#{name}",
        Class.new(ApplicationRecord) do
          self.table_name = tablename

          instance_exec(self, &blk) if blk

          @name = name.to_s
          def self.name
            @name.to_s
          end
        end
      )
    end

    def initialize
      @tid = SecureRandom.hex(5)

      model(:document,
        id: 'text primary key',
        doc_id: :text,
        package_id: :bigint,
        round: :int,
        theme: :int,
        question: :int,
        term: :text,
        count: :int,

        role: :text, # train or test?
        cat: :text # correct category
      ) do
        enum role: { train: 'train', test: 'test' }
      end

      model(:term, term: :text)
      model(:apriori, id: :int, category: :text, probability: :float)
      model(:termprob, term: :text, category: :text, probability: :float)
      model(:docprob, doc_id: :text, category: :text, log_prob: :float)
      model(:doccls, doc_id: :text, yes_p: :float, no_p: :float)
    end

    def prepare(cat)
      @cat = cat

      report(:document)
      puts "Train #{document.train.count}"
      puts "Test #{document.test.count}"

      report(:term)
      report(:apriori)
      pp apriori.all.as_json
      report(:termprob)
      ['yes', 'no'].each do |category|
        [['Best', :desc], ['Worst', :asc]].each do |(word, sort)|
          pp ["#{word} terms for #{category}",
          termprob.where(category:).order(:probability => sort).limit(5).pluck(:term, :probability).to_h]
        end
      end

      report(:docprob)

      report(:doccls)

      self
    end

    def report(model, &blk)
      puts "Filling #{model}"
      start = Time.now
      send("fill_#{model}")
      finish = Time.now
      puts "Filled #{send(model).count} of #{model} in #{(finish - start).round(2)}"
    end

    def fill_document
      cs = StringCleaner.new

      Package
        .select(:id, :structure, :structure_classification)
        .where.not(structure_classification: {})
        .where.not(structure: {})
        .find_in_batches do |batch|
          inserts = []

          batch.each do |package|
            package.structure.each_with_index do |round, round_id|
              round['themes'].each_with_index do |theme, theme_id|
                theme['questions'].each_with_index do |question, question_id|
                  cls_key = [round_id, theme_id, question_id, cat].join('_')
                  cls_y = package.structure_classification[cls_key] || 'null'
                  next if cls_y == 'null'

                  s = [question['answers'] + [question['question_text']]].join(' ')
                  s = cs.clean(s)
                  next if s.blank?

                  s.split.tally.each do |term, count|
                    doc_id = [package.id, cls_key].join('_')
                    inserts << {
                      doc_id:,
                      id: [doc_id, term].join('_'),
                      package_id: package.id,
                      round: round_id,
                      theme: theme_id,
                      question: question_id,
                      term:,
                      count:,
                      cat: cls_y
                    }
                  end
                end
              end
            end
          end

          document.import(inserts)
      end

      r = Random.new(123)

      trains = []
      tests = []

      document.ids.each do |id|
        to_train = r.rand(100) < 75

        if to_train
          trains << id
        else
          tests << id
        end
      end

      document.where(id: trains).update_all(role: 'train')
      document.where(id: tests).update_all(role: 'test')
    end

    def fill_term
      data = document.train.select('term').distinct
      insert(term, data)
    end

    # Apriori probability of tag being yes/no
    def fill_apriori
      # distinct documents
      n = document.train.select(:doc_id).distinct.count

      yes = document.train.select(:doc_id).where(cat: :yes).distinct.count.to_f / n
      no = document.train.select(:doc_id).where(cat: :no).distinct.count.to_f / n

      apriori.create!(category: :yes, probability: yes)
      apriori.create!(category: :no, probability: no)
    end

    def all_terms
      document.train.select(:term).distinct
    end

    def fill_termprob
      all_terms_n = all_terms.count

      term_cat = all_terms
        .reselect('term', 'cat')
        .joins("CROSS JOIN (values ('yes'), ('no')) s(cat)")

      real_counts = document.train
        .group('cat', 'term')
        .select(
          'term',
          'cat',
          "sum(count) as real_count"
        )

      category_len = Package
        .from(real_counts)
        .select('cat', 'sum(real_count) as category_len')
        .group('cat')

      data = document
        .from(term_cat)
        .select(
          'term',
          'cat',
          # Laplace smoothing for log_p
          "LOG((coalesce(real_count, 0) + 1)::float / (category_len + #{all_terms_n})) AS log_p")
        .joins("LEFT OUTER JOIN (#{real_counts.to_sql}) rr using (term, cat)")
        .joins("JOIN (#{category_len.to_sql}) clen using(cat)")

      insert(termprob, data)
    end

    def fill_docprob
      # prob = p(cat) * PRODUCT[p(word|cat)]
      # log(prob) = log(p(cat)) + SUM[log(p(word|cat))]

      # doc term counts but only for good terms
      doc_term_count = document.train
        .select('doc_id', 'term', "count")
        .joins("JOIN (#{all_terms.to_sql}) s USING (term)")

      doc_term_count_probs = document
        .from(doc_term_count)
        .select('doc_id', 'term', 'category', 'count * probability as term_log_prob')
        .joins("JOIN #{termprob.table_name} USING (term)")

      doc_terms_log_prob = Package
        .from(doc_term_count_probs)
        .select('doc_id', 'category', 'sum(term_log_prob) as term_log_prob_sum')
        .group('doc_id', 'category')

      with_apriori = Package
        .from(doc_terms_log_prob)
        .select('doc_id', 'category',
          "(term_log_prob_sum + log(#{apriori.table_name}.probability)) AS log_prob")
        .joins("JOIN #{apriori.table_name} using (category)")

      insert(docprob, with_apriori)
    end

    def fill_doccls
      d = document.test
        .select(:doc_id, :cat, 'jsonb_object_agg(category, log_prob) as probs')
        .joins("JOIN #{docprob.table_name} USING (doc_id)")
        .group(:doc_id, :cat)

      yes_p = "coalesce((probs->'yes')::float, '-infinity')"
      no_p = "coalesce((probs->'no')::float, '-infinity')"
      expr = <<~SQL.squish
              case
    when #{yes_p} = #{no_p} then 'null'
    when #{yes_p} > #{no_p} then 'yes'
              end
            SQL


      c = document
          .from(d)
          .select(
            :doc_id,
            :cat,
            "#{expr} inferred",
            "cat = #{expr} correct"
            )

      test_doc_ids = document.test.select(:doc_id).distinct.pluck(:doc_id)

      n = test_doc_ids.count

      texts = []
      ['yes', 'null', 'no'].each do |correct|
        ['yes', 'null', 'no'].each do |inferred|
          count = document
            .from(c, document.table_name)
            .where(cat: correct, inferred:, doc_id: test_doc_ids)
            .count
          texts << "#{correct} as #{inferred} = #{count}"
        end
      end

      texts.each do |t|
        puts t
      end

      raise 'kek'
    end


    ## utils

    def ts_occurs
      'array_length((ts).positions, 1)'
    end

    def unnest_ts(as = true)
      "unnest(searchable) AS ts"
    end

    def execute(sql)
      ApplicationRecord.connection.execute(sql)
    end

    def insert(table, data)
      d = data.respond_to?(:to_sql) ? data.to_sql : data
      execute "insert into #{table.table_name} #{d}"
    end
  end
end
