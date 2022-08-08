require 'rails_helper'

RSpec.describe Classification::Classifier do
  RSpec::Matchers.define :approx do |expected|
    match do |actual|
      expect(actual).to be_within(0.001).of(expected)
    end
  end

  def p_words(words)
    create(:package, category_text: words)
  end

  let(:instance) { described_class.new }

  let_it_be(:pa) { p_words(%w[hasta la vista baby la vista la]) }
  let_it_be(:pb) { p_words(%w[hasta one two three]) }

  let(:len) { instance.class.const_get(:Len) }
  let(:tf) { instance.class.const_get(:Tf) }
  let(:idf) { instance.class.const_get(:Idf) }

  describe 'len' do
    it 'has correct document lengths' do
      expect(len.all).to include(
        have_attributes(
          package: pa,
          len: 7
        ),
        have_attributes(
          package: pb,
          len: 4
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
          tf: approx(1.0 / 7)
        ),
        have_attributes(
          package: pa,
          term: 'la',
          tf: approx(3.0 / 7)
        ),
        have_attributes(
          package: pb,
          term: 'one',
          tf: approx(1.0 / 4)
        )
      )
    end
  end

  describe 'idf' do
    it 'has correct inverse document frequency' do
      expect(idf.all).to include(
        have_attributes(
          term: 'hasta',
          idf: Math.log10(2.0 / 2)
        ),
        have_attributes(
          term: 'one',
          idf: Math.log10(2.0 / 1)
        )
      )
    end
  end
end
