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

      iv = "@#{name}"
      instance_variable_set(
        iv,
        Class.new(ApplicationRecord) do
          self.table_name = tablename

          instance_exec(self, &blk) if blk

          @name = name.to_s
          def self.name
            @name.to_s
          end
        end
      )

      @all_models << instance_variable_get(iv)
    end

    def initialize
      @all_models = []
      @tid = SecureRandom.hex(5)

      model(:document,
        id: 'text primary key',
        clean_text: :text,

        y_cat: 'text not null' # correct category
      )

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


      model(:term, term: 'text primary key', docs: :int)
      model(:apriori, id: :int, cat: :text, log_p: :float)
      model(:termprob, term: :text, cat: :text, log_p: :float)
      model(:docprob, doc_id: :text, cat: :text, log_p: :float)
      model(:doccls, doc_id: :text, yes_p: :float, no_p: :float)
      model(:result, id: :text, cat: :text)

      execute "create index on #{termprob.table_name} (term)"
    end

    def close
      @all_models.reverse.each do |model|
        execute "drop table #{model.table_name}"
      end
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
      ['yes', 'no'].each do |cat|
        [['Best', :desc], ['Worst', :asc]].each do |(word, sort)|
          pp ["#{word} terms for #{cat}",
          termprob.where(cat:).order(:log_p => sort).limit(5).pluck(:term, :log_p).to_h]
        end
      end

      self
    end

    def report(model, &blk)
      puts "Filling #{model}"
      start = Time.current
      send("fill_#{model}")
      finish = Time.current
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


    def question_text(package:, round:, theme:, question:)
      strings = [
        *question['answers'],
        question['question_text'],
        round['name'],
        theme['name'],
        package.name
      ]

      string_cleaner.clean(strings.join(' '))
    end

    SEED = 123
    TRAIN_PORTION = 0.85

    def fill_document
      tp_scope = train_packages
        .where.not(structure_classification: {}) # train ony on mapped packages

      tp_scope
        .select(:id, :name, :structure, :structure_classification)
        .find_in_batches.with_index do |batch, i|
          puts "Batch #{i}/#{tp_scope.count / 1000}"

          inserts = []

          batch.each do |package|
            iter_structure(package.structure) do |round, round_id, theme, theme_id, question, question_id|
              id = [package.id, round_id, theme_id, question_id].join('_')
              cls_key = [round_id, theme_id, question_id, cat].join('_')
              y_cat = package.structure_classification&.[](cls_key) || 'null'

              next if y_cat == 'null'

              clean_text = question_text(package:, round:, theme:, question:)
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
        .select(:id, :name, :structure)
        .find_in_batches.with_index do |batch, i|
          inserts = []

          batch.each do |package|
            iter_structure(package.structure) do |round, round_id, theme, theme_id, question, question_id|
              id = [package.id, round_id, theme_id, question_id].join('_')
              clean_text = question_text(package:, round:, theme:, question:)
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
          document.select(
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
        .joins("join #{term.table_name} ON (ts).lexeme = #{term.table_name}.term")

      insert(
        predict_docterm,
        " (document_id, term, occurences) select * from (#{data.to_sql}) s"
      )
    end

    def fill_term
      data = document
        .joins("JOIN #{docterm.table_name} ON document_id = #{document.table_name}.id")
        .select('term', 'count(distinct document_id) as docs')
        .group(:term)

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

      yes = log(document.where(y_cat: :yes).count.to_f / n)
      no = log(document.where(y_cat: :no).count.to_f / n)

      apriori.create!(cat: :yes, log_p: yes)
      apriori.create!(cat: :no, log_p: no)
    end

    def fill_termprob
      all_terms_n = term.count

      # (term, cat)
      term_cat = term
        .reselect('term', 'cat', 'docs')
        .joins("CROSS JOIN (values ('yes'), ('no')) s(cat)")

      # occurences of term in cat
      real_counts = document
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

      all_docs_len = document.count


      data = Package
        .from(term_cat)
        .select(
          'term',
          'cat',
          # Laplace smoothing (add one of each word to all documents)
          # multiply (add) idf: log[|all docs|] - log[|docs having term|]
          <<~SQL
            LOG((coalesce(real_count, 0) + 1)::float)
            - LOG(category_len + #{all_terms_n})
            + LOG(1 + #{all_docs_len})
            - LOG(1 + docs)
            as log_p
          SQL
        )
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

    def truncate(x)
      x.connection.truncate(x.table_name)
    end

    def predict(packages, give_documents)
      predict_docterm.connection.truncate_tables(
        *[docprob, predict_docterm, predict_document].map(&:table_name)
      )

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
      expr = <<~SQL.squish
              case
                when #{yes_p} > #{no_p} then 1
                else 0
              end
            SQL

      if give_documents
        return predict_document
          .from(d)
          .select('id', "case #{expr} when 1 then 'yes' else 'no' end cat")
      end

      package_id = "split_part(id, '_', 1)::bigint"

      predict_document
        .from(d)
        .select(
          "#{package_id} id",
          # sum skips nulls, so it is number of 1 / (total number)
          "sum(#{expr})::float / count(*) match_part",
        )
        .group(package_id)
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
