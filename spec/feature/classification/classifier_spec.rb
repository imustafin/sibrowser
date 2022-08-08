require 'rails_helper'

RSpec.describe Classification::Classifier do
  RSpec::Matchers.define :approx do |expected|
    match do |actual|
      expect(actual).to be_within(0.001).of(expected)
    end
  end

  def pk(tags, words)
    create(:package, name: words.join(' '), tags:)
  end

  let(:instance) { described_class.new.prepare }

  let_it_be(:pa) { pk(['музыка'], %w[hasta la vista baby la vista la lindemann]) }
  let_it_be(:pb) { pk(['аниме'], %w[hasta one two three anime naruto]) }
  let_it_be(:pc) { pk(['аниме'], %w[anime naruto sakura]) }

  let(:len) { instance.class.const_get(:Len) }
  let(:tf) { instance.class.const_get(:Tf) }
  let(:idf) { instance.class.const_get(:Idf) }
  let(:pcategory) { instance.class.const_get(:Pcategory) }
  let(:apriori) { instance.class.const_get(:Apriori) }

  describe 'len' do
    it 'has correct document lengths' do
      expect(len.all).to include(
        have_attributes(
          package: pa,
          len: 9
        ),
        have_attributes(
          package: pb,
          len: 7
        )
      )
    end
  end

  describe 'tf' do
    it 'has correct term frequencies' do
      expect(tf.all).to include(
        have_attributes(
          package: pa,
          term: 'hasta',
          tf: approx(1.0 / 9)
        ),
        have_attributes(
          package: pa,
          term: 'la',
          tf: approx(3.0 / 9)
        ),
        have_attributes(
          package: pb,
          term: 'one',
          tf: approx(1.0 / 7)
        )
      )
    end
  end

  describe 'idf' do
    it 'has correct inverse document frequency' do
      n = 3.0 # number of documents

      expect(idf.all).to include(
        have_attributes(
          term: 'hasta',
          idf: Math.log10(n / 2)
        ),
        have_attributes(
          term: 'one',
          idf: Math.log10(n / 1)
        )
      )
    end
  end

  describe 'pcategory' do
    it 'has records for package-category' do
      expect(pcategory.all).to contain_exactly(
        have_attributes(
          package: pa,
          category: 'music'
        ),
        have_attributes(
          package: pb,
          category: 'anime'
        ),
        have_attributes(
          package: pc,
          category: 'anime'
        )
      )
    end
  end

  describe 'apriori' do
    it 'has apriori category probabilities and 0 for not present cats' do
      # We do laplace smoothing
      # add 1 to divisible, add n to divider

      n = 3 # number of documents

      expect(apriori.all).to include(
        have_attributes(
          category: 'music',
          probability: approx(1.0 / n)
        ),
        have_attributes(
          category: 'anime',
          probability: approx(2.0 / n)
        ),
        have_attributes(
          category: 'movies',
          probability: approx(0)
        )
      )
    end
  end
end
