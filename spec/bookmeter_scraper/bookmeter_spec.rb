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
end
