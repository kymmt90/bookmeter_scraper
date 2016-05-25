require 'spec_helper'

RSpec.describe BookmeterScraper::Bookmeter do
  shared_context 'valid user ID' do
    let(:user_id) { '000000' }
  end

  shared_context 'invalid user ID' do
    let(:user_id) { '00a000' }
  end

  describe BookmeterScraper::Scraper::Book do
    subject { BookmeterScraper::Scraper::Book.new }
    it { is_expected.to respond_to :name }
    it { is_expected.to respond_to :author }
    it { is_expected.to respond_to :read_dates }
    it { is_expected.to respond_to :uri }
    it { is_expected.to respond_to :image_uri }
  end

  describe BookmeterScraper::Scraper::User do
    subject { BookmeterScraper::Scraper::User.new }
    it { is_expected.to respond_to :name }
    it { is_expected.to respond_to :id }
    it { is_expected.to respond_to :uri }
  end

  describe 'URI helper methods' do
    describe '.mypage_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper.mypage_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper.mypage_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.read_books_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper.read_books_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklist" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper.read_books_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.reading_books_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper.reading_books_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklistnow" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper.reading_books_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.tsundoku_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper.tsundoku_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklisttun" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper.tsundoku_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.wish_list_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper.wish_list_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklistpre" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper.wish_list_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.followings_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper.followings_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/favorite_user" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper.followings_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.followers_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper.followers_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/favorited_user" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper.followers_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end
  end

  describe '.log_in' do
    before do
      File.open('spec/fixtures/profile.html') do |f|
        stub_request(:get, 'http://bookmeter.com/u/000000')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end

      File.open('spec/fixtures/home.html') do |f|
        stub_request(:get, 'http://bookmeter.com/')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end
    end

    describe 'taking arguments' do
      let(:bookmeter) { BookmeterScraper::Bookmeter.log_in('mail', 'password') }

      context 'taking valid mail and password' do
        before do
          File.open('spec/fixtures/login.html') do |f|
            stub_request(:get, 'http://bookmeter.com/login')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          stub_request(:post, 'http://bookmeter.com/login')
            .to_return(status: 302, headers: { 'Location' => '/', 'Content-Type' => 'text/html' })
        end

        describe '#logged_in?' do
          subject { bookmeter.logged_in? }
          it { is_expected.to be_truthy }
        end

        describe '#log_in_user_id?' do
          subject { bookmeter.log_in_user_id }
          it { is_expected.to eq '000000' }
        end
      end

      context 'taking invalid mail and password' do
        before do
          File.open('spec/fixtures/login.html') do |f|
            stub_request(:any, 'http://bookmeter.com/login')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end
        end

        describe '#logged_in?' do
          subject { bookmeter.logged_in? }
          it { is_expected.to be_falsey }
        end

        describe '#log_in_user_id?' do
          subject { bookmeter.log_in_user_id }
          it { is_expected.to be_nil }
        end
      end
    end

    describe 'taking a block' do
      let(:bookmeter) do
        BookmeterScraper::Bookmeter.log_in do |config|
          config.mail     = 'mail'
          config.password = 'password'
        end
      end

      context 'taking valid mail and password' do
        before do
          File.open('spec/fixtures/login.html') do |f|
            stub_request(:get, 'http://bookmeter.com/login')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          stub_request(:post, 'http://bookmeter.com/login')
            .to_return(status: 302, headers: { 'Location' => '/', 'Content-Type' => 'text/html' })
        end

        describe '#logged_in?' do
          subject { bookmeter.logged_in? }
          it { is_expected.to be_truthy }
        end

        describe '#log_in_user_id?' do
          subject { bookmeter.log_in_user_id }
          it { is_expected.to eq '000000' }
        end
      end

      context 'taking invalid mail and password' do
        before do
          File.open('spec/fixtures/login.html') do |f|
            stub_request(:any, 'http://bookmeter.com/login')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end
        end

        describe '#logged_in?' do
          subject { bookmeter.logged_in? }
          it { is_expected.to be_falsey }
        end

        describe '#log_in_user_id?' do
          subject { bookmeter.log_in_user_id }
          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe '#log_in' do
    let(:bookmeter) { BookmeterScraper::Bookmeter.new }

    before do
      File.open('spec/fixtures/home.html') do |f|
        stub_request(:get, 'http://bookmeter.com/')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end

      File.open('spec/fixtures/profile.html') do |f|
        stub_request(:get, 'http://bookmeter.com/u/000000')
          .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
      end
    end

    describe 'taking arguments' do
      context 'taking valid mail / password' do
        before do
          File.open('spec/fixtures/login.html') do |f|
            stub_request(:get, 'http://bookmeter.com/login')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          stub_request(:post, 'http://bookmeter.com/login')
            .to_return(status: 302, headers: { 'Location' => '/', 'Content-Type' => 'text/html' })

          bookmeter.log_in('mail', 'valid')
        end

        describe '#logged_in?' do
          subject { bookmeter.logged_in? }
          it { is_expected.to be_truthy }
        end

        describe '#log_in_user_id?' do
          subject { bookmeter.log_in_user_id }
          it { is_expected.to eq '000000' }
        end
      end

      context 'taking invalid mail / password' do
        before do
          File.open('spec/fixtures/login.html') do |f|
            stub_request(:any, 'http://bookmeter.com/login')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          bookmeter.log_in('mail', 'invalid')
        end

        describe '#logged_in?' do
          subject { bookmeter.logged_in? }
          it { is_expected.to be_falsey }
        end

        describe '#log_in_user_id?' do
          subject { bookmeter.log_in_user_id }
          it { is_expected.to be_nil }
        end
      end
    end

    describe 'taking a block' do
      context 'taking valid mail / password' do
        before do
          File.open('spec/fixtures/login.html') do |f|
            stub_request(:get, 'http://bookmeter.com/login')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          stub_request(:post, 'http://bookmeter.com/login')
            .to_return(status: 302, headers: { 'Location' => '/', 'Content-Type' => 'text/html' })

          bookmeter.log_in do |config|
            config.mail = 'mail'
            config.password = 'valid'
          end
        end

        describe '#logged_in?' do
          subject { bookmeter.logged_in? }
          it { is_expected.to be_truthy }
        end

        describe '#log_in_user_id?' do
          subject { bookmeter.log_in_user_id }
          it { is_expected.to eq '000000' }
        end
      end

      context 'taking invalid mail / password' do
        before do
          File.open('spec/fixtures/login.html') do |f|
            stub_request(:any, 'http://bookmeter.com/login')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          bookmeter.log_in('mail', 'invalid')
        end

        describe '#logged_in?' do
          subject { bookmeter.logged_in? }
          it { is_expected.to be_falsey }
        end

        describe '#log_in_user_id?' do
          subject { bookmeter.log_in_user_id }
          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe '#profile' do
    let(:bookmeter) { BookmeterScraper::Bookmeter.new }

    context 'taking valid user ID' do
      include_context 'valid user ID'

      before do
        File.open('spec/fixtures/profile.html') do |f|
          stub_request(:any, 'http://bookmeter.com/u/000000')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      subject { bookmeter.profile(user_id) }
      it { is_expected.not_to be_nil }
    end

    context 'taking invalid user ID' do
      include_context 'invalid user ID'
      it 'raises ArgumentError' do
        expect { bookmeter.profile(user_id) }.to raise_error ArgumentError
      end
    end
  end

  describe 'books fetching methods' do
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

    describe '#read_books' do
      let(:bookmeter) { BookmeterScraper::Bookmeter.new }

      context 'taking valid user ID' do
        include_context 'valid user ID'

        let(:agent) { BookmeterScraper::Agent.new }
        let(:scraper) { BookmeterScraper::Scraper.new }

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklist')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          set_up_logging_in(agent, scraper, bookmeter)
        end

        subject { bookmeter.read_books(user_id).count }
        it { is_expected.to eq 3 }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { bookmeter.read_books(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '#read_books_in' do
      let(:bookmeter) { BookmeterScraper::Bookmeter.new }

      context 'taking valid user ID' do
        include_context 'valid user ID'

        let(:agent) { BookmeterScraper::Agent.new }
        let(:scraper) { BookmeterScraper::Scraper.new }

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklist')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          set_up_logging_in(agent, scraper, bookmeter)
        end

        subject { bookmeter.read_books_in(2016, 2, user_id).count }
        it { is_expected.to eq 2 }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { bookmeter.read_books_in(2016, 2, user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '#reading_books' do
      let(:bookmeter) { BookmeterScraper::Bookmeter.new }

      context 'taking valid user ID' do
        include_context 'valid user ID'

        let(:agent) { BookmeterScraper::Agent.new }
        let(:scraper) { BookmeterScraper::Scraper.new }

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklistnow')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          set_up_logging_in(agent, scraper, bookmeter)
        end

        subject { bookmeter.reading_books(user_id).count }
        it { is_expected.to eq 3 }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { bookmeter.reading_books(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '#tsundoku' do
      let(:bookmeter) { BookmeterScraper::Bookmeter.new }

      context 'taking valid user ID' do
        include_context 'valid user ID'

        let(:agent) { BookmeterScraper::Agent.new }
        let(:scraper) { BookmeterScraper::Scraper.new }

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklisttun')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          set_up_logging_in(agent, scraper, bookmeter)
        end

        subject { bookmeter.tsundoku(user_id).count }
        it { is_expected.to eq 3 }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { bookmeter.tsundoku(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '#wish_list' do
      let(:bookmeter) { BookmeterScraper::Bookmeter.new }

      context 'taking valid user ID' do
        include_context 'valid user ID'

        let(:agent) { BookmeterScraper::Agent.new }
        let(:scraper) { BookmeterScraper::Scraper.new }

        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklistpre')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end

          set_up_logging_in(agent, scraper, bookmeter)
        end

        subject { bookmeter.wish_list(user_id).count }
        it { is_expected.to eq 3 }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { bookmeter.wish_list(user_id) }.to raise_error ArgumentError
        end
      end
    end
  end
end
