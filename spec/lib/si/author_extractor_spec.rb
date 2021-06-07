require 'rails_helper'

RSpec.describe Si::AuthorExtractor do
  describe '.extract' do
    it 'drops редакторы:' do
      expect(
        described_class.extract([
          'редакторы: александра косолапова (запорожье), владимир островский (киев), евгений шляхов (днепропетровск)'
        ])
      ).to eq([
        'александра косолапова (запорожье)',
        'владимир островский (киев)',
        'евгений шляхов (днепропетровск)',
      ])
    end

    it 'drops разработка игры:' do
      expect(
        described_class.extract([
          'разработка игры: satanicat'
        ])
      ).to eq([
        'satanicat'
      ])
    end

    it 'splits by поддержка и тестирование: and креативная идея:' do
      expect(
        described_class.extract([
          'разработка игры: satanicat поддержка и тестирование: h0okech креативная идея: amensal'
        ])
      ).to eq([
        'satanicat',
        'h0okech',
        'amensal'
      ])
    end

    it 'splits by и' do
      expect(
        described_class.extract([
          'keeperomerta, 3zhopec, lacost и алинакрутяк'
        ])
      ).to eq([
        'keeperomerta',
        '3zhopec',
        'lacost',
        'алинакрутяк'
      ])
    end

    it 'splits by при поддержке' do
      expect(
        described_class.extract([
          'nami tsukiyami при поддержке open society foundations'
        ])
      ).to eq([
        'nami tsukiyami',
        'open society foundations'
      ])
    end

    it 'drop final dot' do
      expect(described_class.extract([
          'диктатор из беларуси, человек из-под шконки и игоръ.'
        ])
      ).to eq([
        'диктатор из беларуси',
        'человек из-под шконки',
        'игоръ'
      ])
    end

    describe 'quote sanitization' do
      it 'sanitizes spaces after double quotes' do
        expect(
          described_class.extract([
            'никитка "утомленный солнцем"михалков'
          ])
        ).to eq([
          'никитка "утомленный солнцем" михалков'
        ])
      end

      it 'does not add space before parentheses' do
        expect(
          described_class.extract([
            'меганекко (иногда "очёчки")'
          ])
        ).to eq([
          'меганекко (иногда "очёчки")'
        ])
      end

      it 'sanitizes spaces before double quotes' do
        expect(
          described_class.extract([
            'stepan"yainsomnia"fedoseev'
          ])
        ).to eq([
          'stepan "yainsomnia" fedoseev'
        ])
      end

      it 'keeps correct quotation' do
        expect(
          described_class.extract([
            'дмитрий "faarooq" петухов'
          ])
        ).to eq([
          'дмитрий "faarooq" петухов'
        ])
      end

      it 'removes unneccessary space before double quote' do
        expect(
          described_class.extract([
            'дмитрий "фарук " петухов'
          ])
        ).to eq([
          'дмитрий "фарук" петухов'
        ])
      end
    end

    it 'drops неизвестно, drops составитель -' do
      expect(
        described_class.extract([
          'неизвестно, составитель - тиводор'
        ])
      ).to eq([
        'тиводор'
      ])
    end

    it 'splits by aka' do
      expect(
        described_class.extract([
          'мразотная бабуля aka williamdrejv'
        ])
      ).to eq([
        'мразотная бабуля',
        'williamdrejv'
      ])
    end

    it 'splits by feat. and &' do
      expect(
        described_class.extract([
          'axel_trevors feat. 4nimemer & ыф'
        ])
      ).to eq([
        'axel_trevors',
        '4nimemer',
        'ыф'
      ])
    end

    it 'drops т.д' do
      expect(
        described_class.extract([
          'тузо aka пузо aka кантузо и т.д'
        ])
      ).to eq([
        'тузо',
        'пузо',
        'кантузо'
      ])
    end

    it 'splits by a.k[.]' do
      expect(
        described_class.extract([
          'bloodyslave a.k. argus a.k vlad'
        ])
      ).to eq([
        'bloodyslave',
        'argus',
        'vlad'
      ])
    end

    it 'splits by russian а.к.а' do
      expect(
        described_class.extract([
          'фрэнки поттс а.к.а тебя ебет?'
        ])
      ).to eq([
        'фрэнки поттс',
        'тебя ебет?'
      ])
    end

    it 'splits by |' do
      expect(
        described_class.extract([
          'tonya | konstantin gunnarsen'
        ])
      ).to eq([
        'tonya',
        'konstantin gunnarsen'
      ])
    end

    it 'splits by /' do
      expect(
        described_class.extract([
          'tonya / konstantin gunnarsen'
        ])
      ).to eq([
        'tonya',
        'konstantin gunnarsen'
      ])
    end

    it 'keeps urls' do
      expect(
        described_class.extract([
          'https://vk.com/tvoypapapidor'
        ])
      ).to eq([
        'https://vk.com/tvoypapapidor'
      ])
    end

    it 'splits by ;' do
      expect(
        described_class.extract([
          'господин зыков; господин зап'
        ])
      ).to eq([
        'господин зыков',
        'господин зап'
      ])
    end

    it 'splits by and' do
      expect(
        described_class.extract([
          'лелуш британский and neko'
        ])
      ).to eq([
        'лелуш британский',
        'neko'
      ])
    end

    it 'splits by featuring' do
      expect(
        described_class.extract([
          'axel_trevors featuring ыф'
        ])
      ).to eq([
        'axel_trevors',
        'ыф'
      ])
    end

    it 'keeps 1337 володя' do
      expect(
        described_class.extract([
          '|30/\ () |) я пораквасить'
        ])
      ).to eq([
        '|30/\ () |) я пораквасить'
      ])
    end

    it 'drops final dots in names' do
      expect(
        described_class.extract([
          'персик. лимпопо. махито.'
        ])
      ).to eq([
        'персик',
        'лимпопо',
        'махито'
      ])
    end

    it 'drops скомпилировал' do
      expect(
        described_class.extract([
          'скомпилировал keringlore'
        ])
      ).to eq([
        'keringlore'
      ])
    end

    it 'keeps s.t.a.l.k.e.r case' do
      expect(
        described_class.extract([
          'г.л.а.д'
        ])
      ).to eq([
        'г.л.а.д'
      ])
    end
  end
end
