require 'rails_helper'

RSpec.describe Classification::Classifier do
  def cp(tag, category_text)
    create(:package, tags: [tag], category_text:)
  end

  let!(:a1) { cp('anime', 'назовите тайтл') }
  let!(:a2) { cp('anime', 'тайтл наруто тайтл') }
  let!(:m1) { cp('music', 'rammstein lindemann назовите amerika') }
  let!(:m2) { cp('music', 'lindemann radio') }

  let(:instance) { described_class.new }

  EPS = 0.0001

  DF = {
    'amerika' => 1,
    'lindemann' => 2,
    'radio' => 1,
    'rammstein' => 1,
    'назов' => 2,
    'нарут' => 1,
    'тайтл' => 2
  }.freeze

  def all_lexemes
    DF.keys
  end

  def df(lexeme)
    DF[lexeme]
  end

  def all_packages
    4
  end

  def idf(lexeme)
    Math.log(all_packages.to_f / df(lexeme), 10)
  end

  describe '#idf' do
    it 'has correct data' do
      expect(instance.idf.all).to match_array(
        all_lexemes.map do |lexeme|
          have_attributes(
            lexeme:,
            df: df(lexeme),
            idf: be_within(EPS).of(idf(lexeme))
          )
        end
      )
    end
  end

  def lens(id)
    {
      a1.id => 2,
      a2.id => 3,
      m1.id => 4,
      m2.id => 2
    }[id]
  end

  def occurs_data
    {
      a1.id => {
        'назов' => 1,
        'тайтл' => 1
      },
      a2.id => {
        'нарут' => 1,
        'тайтл' => 2
      },
      m1.id => {
        'rammstein' => 1,
        'lindemann' => 1,
        'назов' => 1,
        'amerika' => 1
      },
      m2.id => {
        'lindemann' => 1,
        'radio' => 1
      }
    }
  end

  def occurs(id, lexeme)
    occurs_data[id][lexeme]
  end

  def doc_lexemes(id)
    occurs_data[id].keys
  end

  def ids
    occurs_data.keys
  end

  def tfidf(id, lexeme)
    idf(lexeme) * occurs(id, lexeme) / lens(id)
  end

  describe '#package_tfidf' do
    it 'has correct data' do
      expect(instance.package_tfidf.all).to match_array(
        ids.flat_map do |id|
          doc_lexemes(id).map do |lexeme|
            have_attributes(
              package_id: id,
              lexeme:,
              occurs: occurs(id, lexeme),
              tfidf: be_within(EPS).of(tfidf(id, lexeme))
            )
          end
        end
      )
    end
  end

  def magn(id)
    doc_lexemes(id)
      .map { |lex| tfidf(id, lex) ** 2 }
      .sum
      .then { |x| Math.sqrt(x) }
  end

  describe '#magns' do
    it 'has correct data' do
      expect(instance.magns.all).to match_array(
        ids.map do |id|
          have_attributes(
            id:,
            magn: be_within(EPS).of(magn(id))
          )
        end
      )
    end
  end
end
