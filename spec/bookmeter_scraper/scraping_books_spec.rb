require 'spec_helper'

RSpec.describe BookmeterScraper::Scraper do
  shared_context 'valid user ID' do
    let(:user_id) { '000000' }
  end

  shared_context 'invalid user ID' do
    let(:user_id) { '00a000' }
  end

  describe 'scraping books' do
    let!(:agent) { BookmeterScraper::Agent.new }
    let(:scraper) { BookmeterScraper::Scraper.new }

    before do
      File.open('spec/fixtures/login.html') do |f|
        stub_request(:get, 'http://bookmeter.com/login')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end

      stub_request(:post, 'http://bookmeter.com/login')
        .to_return(status: 302, headers: { 'Location' => '/', 'Content-Type' => 'text/html' })
      File.open('spec/fixtures/home.html') do |f|
        stub_request(:get, 'http://bookmeter.com/')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end

      File.open('spec/fixtures/profile.html') do |f|
        stub_request(:get, 'http://bookmeter.com/u/000000')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end

      File.open('spec/fixtures/book_4839928401.html') do |f|
        stub_request(:get, 'http://bookmeter.com/b/4839928401')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end

      File.open('spec/fixtures/book_4873116864.html') do |f|
        stub_request(:get, 'http://bookmeter.com/b/4873116864')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end

      File.open('spec/fixtures/book_4873117437.html') do |f|
        stub_request(:get, 'http://bookmeter.com/b/4873117437')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end
    end

    describe '#fetch_books for read books' do
      context 'taking valid user ID and read books are found' do
        include_context 'valid user ID'

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklist')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        describe 'books' do
          subject { scraper.fetch_books(user_id, :read_books_uri).to_a }
          it { is_expected.not_to be_empty }
          it { is_expected.to include \
            BookmeterScraper::Scraper::Book.new('Web API: The Good Parts',
                                                '水野貴明',
                                                [Time.local(2016, 2, 6)],
                                                'http://bookmeter.com/b/4873116864',
                                                'http://ecx.images-amazon.com/images/I/51GHwTNJgSL._SX230_.jpg'),
            BookmeterScraper::Scraper::Book.new('メタプログラミングRuby 第2版',
                                                'PaoloPerrotta',
                                                [Time.local(2016, 2, 2)],
                                                'http://bookmeter.com/b/4873117437',
                                                'http://ecx.images-amazon.com/images/I/5102wwx0VzL._SX230_.jpg'),
            BookmeterScraper::Scraper::Book.new('ノンデザイナーズ・デザインブック [フルカラー新装増補版]',
                                                'RobinWilliams',
                                                [Time.local(2015, 4, 28), Time.local(2016, 1, 10)],
                                                'http://bookmeter.com/b/4839928401',
                                                'http://ecx.images-amazon.com/images/I/41nvddaG9BL._SX230_.jpg')
          }
        end
      end

      context 'taking valid user ID and read books are not found' do
        include_context 'valid user ID'

        before do
          File.open('spec/fixtures/read_books_notfound.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklist')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :read_books_uri) }
        it { is_expected.to be_empty }
      end

      context 'when not logging in' do
        include_context 'valid user ID'

        before do
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :read_books_uri) }
        it { is_expected.to be_empty }
      end
    end

    describe '#fetch_books for reading_books' do
      before do
        File.open('spec/fixtures/read_books.html') do |f|
          stub_request(:any, 'http://bookmeter.com/u/000000/booklistnow')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      context 'taking valid user ID and reading books are found' do
        include_context 'valid user ID'

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklistnow')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :reading_books_uri).to_a }
        it { is_expected.not_to be_empty }
        it { is_expected.to include \
            BookmeterScraper::Scraper::Book.new('Web API: The Good Parts',
                                                '水野貴明',
                                                [Time.local(2016, 2, 6)],
                                                'http://bookmeter.com/b/4873116864',
                                                'http://ecx.images-amazon.com/images/I/51GHwTNJgSL._SX230_.jpg'),
            BookmeterScraper::Scraper::Book.new('メタプログラミングRuby 第2版',
                                                'PaoloPerrotta',
                                                [Time.local(2016, 2, 2)],
                                                'http://bookmeter.com/b/4873117437',
                                                'http://ecx.images-amazon.com/images/I/5102wwx0VzL._SX230_.jpg'),
            BookmeterScraper::Scraper::Book.new('ノンデザイナーズ・デザインブック [フルカラー新装増補版]',
                                                'RobinWilliams',
                                                [Time.local(2015, 4, 28), Time.local(2016, 1, 10)],
                                                'http://bookmeter.com/b/4839928401',
                                                'http://ecx.images-amazon.com/images/I/41nvddaG9BL._SX230_.jpg')
          }
      end

      context 'taking valid user ID and reading books are not found' do
        include_context 'valid user ID'

        before do
          File.open('spec/fixtures/read_books_notfound.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklistnow')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :reading_books_uri) }
        it { is_expected.to be_empty }
      end

      context 'when not logging in' do
        include_context 'valid user ID'

        before do
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :reading_books_uri) }
        it { is_expected.to be_empty }
      end
    end

    describe '#fetch_books for tsundoku' do
      before do
        File.open('spec/fixtures/read_books.html') do |f|
          stub_request(:any, 'http://bookmeter.com/u/000000/booklisttun')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      context 'taking valid user ID and tsundoku are found' do
        include_context 'valid user ID'

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklisttun')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :tsundoku_uri).to_a }
        it { is_expected.not_to be_empty }
        it { is_expected.to include \
            BookmeterScraper::Scraper::Book.new('Web API: The Good Parts',
                                                '水野貴明',
                                                [Time.local(2016, 2, 6)],
                                                'http://bookmeter.com/b/4873116864',
                                                'http://ecx.images-amazon.com/images/I/51GHwTNJgSL._SX230_.jpg'),
            BookmeterScraper::Scraper::Book.new('メタプログラミングRuby 第2版',
                                                'PaoloPerrotta',
                                                [Time.local(2016, 2, 2)],
                                                'http://bookmeter.com/b/4873117437',
                                                'http://ecx.images-amazon.com/images/I/5102wwx0VzL._SX230_.jpg'),
            BookmeterScraper::Scraper::Book.new('ノンデザイナーズ・デザインブック [フルカラー新装増補版]',
                                                'RobinWilliams',
                                                [Time.local(2015, 4, 28), Time.local(2016, 1, 10)],
                                                'http://bookmeter.com/b/4839928401',
                                                'http://ecx.images-amazon.com/images/I/41nvddaG9BL._SX230_.jpg')
          }
      end

      context 'taking valid user ID and tsundoku are not found' do
        include_context 'valid user ID'

        before do
          File.open('spec/fixtures/read_books_notfound.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklisttun')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :tsundoku_uri) }
        it { is_expected.to be_empty }
      end

      context 'when not logging in' do
        include_context 'valid user ID'

        before do
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :tsundoku_uri) }
        it { is_expected.to be_empty }
      end
    end

    describe '#fetch_books for wish_list' do
      before do
        File.open('spec/fixtures/read_books.html') do |f|
          stub_request(:any, 'http://bookmeter.com/u/000000/booklistpre')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      context 'taking valid user ID and wish list are found' do
        include_context 'valid user ID'

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklistpre')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :wish_list_uri).to_a }
        it { is_expected.not_to be_empty }
        it { is_expected.to include \
            BookmeterScraper::Scraper::Book.new('Web API: The Good Parts',
                                                '水野貴明',
                                                [Time.local(2016, 2, 6)],
                                                'http://bookmeter.com/b/4873116864',
                                                'http://ecx.images-amazon.com/images/I/51GHwTNJgSL._SX230_.jpg'),
            BookmeterScraper::Scraper::Book.new('メタプログラミングRuby 第2版',
                                                'PaoloPerrotta',
                                                [Time.local(2016, 2, 2)],
                                                'http://bookmeter.com/b/4873117437',
                                                'http://ecx.images-amazon.com/images/I/5102wwx0VzL._SX230_.jpg'),
            BookmeterScraper::Scraper::Book.new('ノンデザイナーズ・デザインブック [フルカラー新装増補版]',
                                                'RobinWilliams',
                                                [Time.local(2015, 4, 28), Time.local(2016, 1, 10)],
                                                'http://bookmeter.com/b/4839928401',
                                                'http://ecx.images-amazon.com/images/I/41nvddaG9BL._SX230_.jpg')
          }
      end

      context 'taking valid user ID and wish list are not found' do
        include_context 'valid user ID'

        before do
          File.open('spec/fixtures/read_books_notfound.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklistpre')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :wish_list_uri) }
        it { is_expected.to be_empty }
      end

      context 'when not logging in' do
        include_context 'valid user ID'

        before do
          scraper.agent = agent
        end

        subject { scraper.fetch_books(user_id, :wish_list_uri) }
        it { is_expected.to be_empty }
      end
    end

    describe '#fetch_books for invalid arguments' do
      it 'raises ArgumentError when taking invalid user ID' do
        expect { scraper.fetch_books('a00000', :read_books_uri) }.to raise_error ArgumentError
      end

      it 'raises ArgumentError when taking invalid URI method name' do
        expect { scraper.fetch_books('000000', :invalid_uri) }.to raise_error ArgumentError
      end
    end
  end
end
