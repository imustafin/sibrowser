namespace :classify do
  desc "Classify packages"
  task run: :environment do
    data = File.read('classifier.dat')

    STDIN.each_slice(100) do |slice|
      c = Classify.new(Marshal.load(data))
      slice.each do |line|
        id, text, cats = JSON.parse(line)
        puts [id, c.classify(text)].to_json
      end
    end
  end

  desc "Print params for classification, done on backend"
  task print_params: :environment do
    Classify.print_params(true)
  end

  desc "Print params for classification for unclassified packages"
  task print_params_unclassified: :environment do
    Classify.print_params(false)
  end

  desc "Builds new model with packages from stdin"
  task train: :environment do
    c = Classify.new
    STDIN.each do |line|
      line = JSON.parse(line)
      c.add(line[1], line[2])
    end

    STDERR.puts "Using GSL/#{GSL::VERSION} RubyGSL/#{GSL::RUBY_GSL_VERSION}"
    STDERR.puts "Building index"
    t1 = Time.now
    c.build
    t2 = Time.now
    STDERR.puts "Index built in #{t2 - t1} seconds"

    File.open('classifier.dat', 'wb') { |f| f.write(c.dump) }
  end

  desc "Sets category_scores, done on backend"
  task update: :environment do
    puts "UPDATE"
    cur_package = nil
    h = nil

    STDIN.each do |line|
      line = JSON.parse(line)
      package = line['package']
      if package != cur_package
        Package.where(id: cur_package).update_all(predicted_categories: h) if cur_package

        cur_package = package
        h = {}
      end

      h.deep_merge!(
        line['round'].to_s => {
          line['theme'].to_s => {
            line['question'].to_s => line['cat']
          }
        }
      )
    end

    Package.where(id: cur_package).update_all(predicted_categories: h)
  end
end
