module Classification
  class Classifier
    attr_accessor :tid, :cat, :train_packages

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
        clean_text: :text,

        y_cat: :text # correct category
      ) do
        scope :with_cat, ->{ where.not(y_cat: nil) }
      end

      model(:predict_document,
        id: 'text primary key',
        clean_text: :text
      )

      model(:docterm,
        id: 'serial primary key',
        document_id: "text references #{document.table_name}(id)",
        term: :text,
        occurences: :int
      )

      model(:predict_docterm,
        id: 'serial primary key',
        document_id: "text references #{predict_document.table_name}(id)",
        term: :text,
        occurences: :int
      )


      model(:term, term: :text)
      model(:apriori, id: :int, cat: :text, log_p: :float)
      model(:termprob, term: :text, cat: :text, log_p: :float)
      model(:docprob, doc_id: :text, cat: :text, log_p: :float)
      model(:doccls, doc_id: :text, yes_p: :float, no_p: :float)
      model(:result, id: :text, cat: :text)
    end

    def train(dataset, cat)
      @cat = cat
      @train_packages = dataset

      report(:document)
      puts "Distribution"
      puts document.group(:y_cat).count

      report(:docterm)
      puts "Text #{document.first.clean_text}"
      puts "  has terms #{docterm.where(document_id: document.first.id).pluck(:term)}"

      report(:term)

      report(:apriori)
      apriori.all.as_json.map do |row|
        log_p = row['log_p']
        p = log_p.nil? ? 0 : exp(log_p)

        puts "#{row['cat']}: log_p #{log_p}, p #{p}"
      end

      report(:termprob)
      ['yes', 'no', 'null'].each do |cat|
        [['Best', :desc], ['Worst', :asc]].each do |(word, sort)|
          pp ["#{word} terms for #{cat}",
          termprob.where(cat:).order(:log_p => sort).limit(5).pluck(:term, :log_p).to_h]
        end
      end

      self
    end

    def report(model, &blk)
      puts "Filling #{model}"
      start = Time.now
      send("fill_#{model}")
      finish = Time.now
      puts "Filled #{send(model).count} of #{model} in #{(finish - start).round(2)}"
    end

    def iter_structure(structure)
      structure.each_with_index do |round, round_id|
        round['themes'].each_with_index do |theme, theme_id|
          theme['questions'].each_with_index do |question, question_id|
            yield round, round_id, theme, theme_id, question, question_id
          end
        end
      end
    end

    def string_cleaner
      @string_cleaner ||= StringCleaner.new
    end


    def question_text(round:, theme:, question:)
      strings = [
        *question['answers'],
        question['question_text'],
        round['name'],
        theme['name']
      ]

      string_cleaner.clean(strings.join(' '))
    end

    SEED = 123
    TRAIN_PORTION = 0.85

    def fill_document
      train_packages
        .where.not(structure_classification: {}) # train only on mapped packages
        .select(:id, :structure, :structure_classification)
        .find_in_batches.with_index do |batch, i|
          puts "Batch #{i}/#{train_packages.count / 1000}"

          inserts = []

          batch.each do |package|
            iter_structure(package.structure) do |round, round_id, theme, theme_id, question, question_id|
              id = [package.id, round_id, theme_id, question_id].join('_')
              cls_key = [round_id, theme_id, question_id, cat].join('_')
              y_cat = package.structure_classification&.[](cls_key) || 'null'

              clean_text = question_text(round:, theme:, question:)
              next if clean_text.blank?

              inserts << {
                id:,
                y_cat:,
                clean_text:
              }
            end
          end

          document.import(inserts)
        end
    end

    def fill_predict_document(packages)
      packages
        .select(:id, :structure)
        .find_in_batches.with_index do |batch, i|
          puts "Predict doc batch #{i}/#{packages.count / 1000}"

          inserts = []

          batch.each do |package|
            iter_structure(package.structure) do |round, round_id, theme, theme_id, question, question_id|
              id = [package.id, round_id, theme_id, question_id].join('_')
              clean_text = question_text(round:, theme:, question:)
              next if clean_text.blank?

              inserts << {
                id:,
                clean_text:
              }
            end
          end

          predict_document.import(inserts)
        end
    end

    # Fills (document_id, term, occrences) only for documents which are mapped (with_cat)
    def fill_docterm
      data = document
        .from(
          document.with_cat.select(
            'id as document_id',
            "unnest(to_tsvector('pg_catalog.russian', clean_text)) as ts"))
        .select(
          'document_id',
          '(ts).lexeme as term',
          'array_length((ts).positions, 1) as occurences'
        )
      insert(docterm, " (document_id, term, occurences) select * from (#{data.to_sql}) s")
    end

    def fill_predict_docterm
      data = predict_document
        .from(
          predict_document.select(
            'id as did',
            "unnest(to_tsvector('pg_catalog.russian', clean_text)) as ts"))
        .select(
          "did",
          '(ts).lexeme as term',
          'array_length((ts).positions, 1) as occurences'
        )
        .joins("join #{docterm.table_name} ON (ts).lexeme = #{docterm.table_name}.term")

      insert(
        predict_docterm,
        " (document_id, term, occurences) select * from (#{data.to_sql}) s"
      )
    end

    def fill_term
      data = document
        .with_cat
        .joins("JOIN #{docterm.table_name} ON document_id = #{document.table_name}.id")
        .select('term')
        .distinct

      insert(term, data)
    end

    def log(f)
      Math.log10(f)
    end

    def exp(f)
      10 ** f
    end

    # Apriori probability of tag being yes/no
    def fill_apriori
      # distinct documents
      n = document.count

      yes = log(document.with_cat.where(y_cat: :yes).count.to_f / n)
      no = log(document.with_cat.where(y_cat: :no).count.to_f / n)
      null = log(document.with_cat.where(y_cat: :null).count.to_f / n)

      apriori.create!(cat: :yes, log_p: yes)
      apriori.create!(cat: :no, log_p: no)
      apriori.create!(cat: :null, log_p: null)
    end

    def fill_termprob
      all_terms_n = term.count

      # (term, cat)
      term_cat = term
        .reselect('term', 'cat')
        .joins("CROSS JOIN (values ('yes'), ('no'), ('null')) s(cat)")

      # occurences of term in cat
      real_counts = document.with_cat
        .joins("JOIN #{docterm.table_name} ON #{document.table_name}.id = document_id")
        .group('y_cat', 'term')
        .select(
          'term',
          'y_cat as cat',
          "sum(occurences) as real_count"
        )

      # number of words in cat with repeats
      # Example: 'a a b' = 3
      category_len = Package
        .from(real_counts)
        .select('cat', 'sum(real_count) as category_len')
        .group('cat')

      data = Package
        .from(term_cat)
        .select(
          'term',
          'cat',
          # Laplace smoothing for log_p
          "LOG((coalesce(real_count, 0) + 1)::float) - LOG(category_len + #{all_terms_n}) AS log_p")
        .joins("LEFT OUTER JOIN (#{real_counts.to_sql}) rr using (term, cat)")
        .joins("JOIN (#{category_len.to_sql}) clen using(cat)")

      insert(termprob, data)
    end

    def fill_docprob
      # fill doc probs for predict_document

      # prob = p(cat) * PRODUCT[p(word|cat)]
      # log(prob) = log(p(cat)) + SUM[log(p(word|cat))]

      # test document terms
      doc_term_count = predict_document
        .select(
          "#{predict_document.table_name}.id as id",
          "term",
          "occurences")
        .joins(
          "JOIN #{predict_docterm.table_name} on document_id = #{predict_document.table_name}.id"
        )

      doc_term_count_probs = predict_document
        .from(doc_term_count, :sub)
        .select("sub.id", 'term', 'cat', 'occurences * log_p as term_log_p')
        .joins("JOIN #{termprob.table_name} USING (term)")

      doc_terms_log_prob = Package # packages here is a placeholder for any model
        .from(doc_term_count_probs, :sub)
        .select('sub.id', 'cat', 'sum(term_log_p) as term_log_p_sum')
        .group('sub.id', 'cat')


      with_apriori = Package
        .from(doc_terms_log_prob, :sub)
        .select('sub.id', 'cat',
          "term_log_p_sum + #{apriori.table_name}.log_p AS log_")
        .joins("JOIN #{apriori.table_name} using (cat)")

      insert(docprob, with_apriori)
    end

    def predict(packages, give_documents)
      fill_predict_document(packages)
      fill_predict_docterm

      fill_docprob

      d = predict_document
        .select(:id, 'jsonb_object_agg(cat, log_p) as probs')
        .joins("JOIN #{docprob.table_name} on id = doc_id")
        .group(:id)

      minus_inf = '-999999'
      yes_p = "coalesce((probs->'yes')::float, #{minus_inf})"
      no_p = "coalesce((probs->'no')::float, #{minus_inf})"
      null_p = "coalesce((probs->'null')::float, #{minus_inf})"
      expr = <<~SQL.squish
              case
                when #{yes_p} > greatest(#{no_p}, #{null_p}) then 1
                when #{no_p} > greatest(#{yes_p}, #{null_p}) then 0
                else NULL
              end
            SQL

      if give_documents
        return predict_document
          .from(d)
          .select('id', "case #{expr} when 1 then 'yes' when 0 then 'no' else 'null' end cat")
      end


      package_id = "split_part(id, '_', 1)"

      predict_document
        .from(d)
        .select(
          "#{package_id} package_id",
          # sum skips nulls, so it is number of 1 / (number of 1 or null)
          "sum(#{expr})::float / count(*) match_part",
        )
        .group(package_id)
    end

    def fill_doccls
      d = document.test
        .select(:id, :y_cat, 'jsonb_object_agg(cat, log_p) as probs')
        .joins("JOIN #{docprob.table_name} on id = doc_id")
        .group(:id, :y_cat)

      minus_inf = '-999999'
      yes_p = "coalesce((probs->'yes')::float, #{minus_inf})"
      no_p = "coalesce((probs->'no')::float, #{minus_inf})"
      expr = <<~SQL.squish
              case
    when #{yes_p} = #{no_p} then 'null'
    when #{yes_p} > #{no_p} then 'yes'
    else 'no'
              end
            SQL


      c = document
          .from(d)
          .select(
            :id,
            :y_cat,
            "#{expr} inferred",
            "y_cat = #{expr} correct",
            "#{yes_p} yes_p",
            "#{no_p} no_p"
            )

      test_doc_ids = document.test.ids

      n = test_doc_ids.count

      texts = []

      texts << "Total: #{document.from(c).count}"
      counts = {
        yes: document.from(c).where("y_cat = 'yes'").count,
        no: document.from(c).where("y_cat = 'no'").count
      }

      texts << "Total yes: #{counts[:yes]}"
      texts << "Total no: #{counts[:no]}"

      ['yes', 'no'].each do |correct|
        ['yes', 'no'].each do |inferred|
          count = document
            .from(c, document.table_name)
            .where(y_cat: correct, inferred:, id: test_doc_ids)
            .count

          percent_ok = (count.to_f / counts[correct.to_sym] * 100).round(2)
          texts << "Correct '#{correct}' as Inferred '#{inferred}': #{count} (#{percent_ok}%)"
        end
      end

      retrieved = document.from(c).where("inferred = 'yes'").count.to_f
      relevant = document.from(c).where("y_cat = 'yes'").count.to_f
      relevant_retrieved = document.from(c).where("inferred = 'yes' AND y_cat = 'yes'").count.to_f
      precision = relevant_retrieved / retrieved
      recall = relevant_retrieved / relevant
      texts << "Precision: #{precision.round(2)}"
      texts << "Recall: #{recall.round(2)}"
      f1 = 2 * (precision * recall) / (precision + recall)
      texts << "F1: #{f1.round(2)}"

      texts.each do |t|
        puts t
      end
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
