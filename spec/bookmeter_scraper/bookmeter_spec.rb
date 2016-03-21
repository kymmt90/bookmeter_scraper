require 'spec_helper'

RSpec.describe BookmeterScraper::Bookmeter do
  shared_context 'valid user ID' do
    let(:user_id) { '000000' }
  end

  shared_context 'invalid user ID' do
    let(:user_id) { '00a000' }
  end

  describe 'URI helper methods' do
    describe '.mypage_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.mypage_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.mypage_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.read_books_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.read_books_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklist" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.read_books_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.reading_books_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.reading_books_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklistnow" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.reading_books_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.tsundoku_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.tsundoku_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklisttun" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.tsundoku_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.wish_list_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.wish_list_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklistpre" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.wish_list_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.followings_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.followings_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/favorite_user" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.followings_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.followers_uri' do
      context 'taking valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.followers_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/favorited_user" }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.followers_uri(user_id) }.to raise_error ArgumentError
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
    let(:profile) { bookmeter.profile('000000') }

    context 'from complete profile' do
      before do
        File.open('spec/fixtures/profile.html') do |f|
          stub_request(:any, 'http://bookmeter.com/u/000000')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      describe '#name' do
        subject { profile.name }
        it { is_expected.to eq 'test_user' }
      end

      describe '#gender' do
        subject { profile.gender }
        it { is_expected.to eq '男' }
      end

      describe '#age' do
        subject { profile.age }
        it { is_expected.to eq '30歳' }
      end

      describe '#blood_type' do
        subject { profile.blood_type }
        it { is_expected.to eq 'A型' }
      end

      describe '#job' do
        subject { profile.job }
        it { is_expected.to eq 'IT関係' }
      end

      describe '#address' do
        subject { profile.address }
        it { is_expected.to eq '東京都' }
      end

      describe '#url' do
        subject { profile.url }
        it { is_expected.to eq 'http://www.example.com' }
      end

      describe '#description' do
        subject { profile.description }
        it { is_expected.to eq '私は test-user です。' }
      end
    end

    context 'from imcomplete profile' do
      before do
        File.open('spec/fixtures/imcomplete_profile.html') do |f|
          stub_request(:any, 'http://bookmeter.com/u/000000')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      describe '#name' do
        subject { profile.name }
        it { is_expected.to eq 'test_user' }
      end

      describe '#gender' do
        subject { profile.gender }
        it { is_expected.to be_nil }
      end

      describe '#age' do
        subject { profile.age }
        it { is_expected.to be_nil }
      end

      describe '#blood_type' do
        subject { profile.blood_type }
        it { is_expected.to be_nil }
      end

      describe '#job' do
        subject { profile.job }
        it { is_expected.to eq 'IT関係' }
      end

      describe '#address' do
        subject { profile.address }
        it { is_expected.to eq '東京都' }
      end

      describe '#url' do
        subject { profile.url }
        it { is_expected.to be_nil }
      end

      describe '#description' do
        subject { profile.description }
        it { is_expected.to eq '私は test-user です。' }
      end
    end
  end

  describe 'fetching books' do
    let(:bookmeter) { BookmeterScraper::Bookmeter.new }

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
      context 'taking valid user ID and read books are found' do
        include_context 'valid user ID'
        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklist')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end
          bookmeter.log_in('mail', 'password')
        end

        describe 'a book' do
          subject { bookmeter.read_books(user_id)[0] }
          it { is_expected.not_to be_nil }
          it { is_expected.to respond_to :name }
          it { is_expected.to respond_to :author }
          it { is_expected.to respond_to :read_dates }
          it { is_expected.to respond_to :uri }
          it { is_expected.to respond_to :image_uri }
        end

        describe 'books' do
          subject { bookmeter.read_books(user_id) }
          it { is_expected.not_to be_empty }
          it { is_expected.to include BookmeterScraper::Bookmeter::Book.new('Web API: The Good Parts', '水野貴明', [Time.local(2016, 2, 6)], 'http://bookmeter.com/b/4873116864', 'http://ecx.images-amazon.com/images/I/51GHwTNJgSL._SX230_.jpg'), BookmeterScraper::Bookmeter::Book.new('メタプログラミングRuby 第2版', 'PaoloPerrotta', [Time.local(2016, 2, 2)], 'http://bookmeter.com/b/4873117437', 'http://ecx.images-amazon.com/images/I/5102wwx0VzL._SX230_.jpg'), BookmeterScraper::Bookmeter::Book.new('ノンデザイナーズ・デザインブック [フルカラー新装増補版]', 'RobinWilliams', [Time.local(2015, 4, 28), Time.local(2016, 1, 10)], 'http://bookmeter.com/b/4839928401', 'http://ecx.images-amazon.com/images/I/41nvddaG9BL._SX230_.jpg') }
        end
      end

      context 'taking valid user ID and read books are not found' do
        include_context 'valid user ID'
        before do
          File.open('spec/fixtures/read_books_notfound.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklist')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.read_books(user_id) }
        it { is_expected.to be_empty }
      end

      context 'when not logging in' do
        include_context 'valid user ID'
        subject { bookmeter.read_books(user_id) }
        it { is_expected.to be_empty }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.new.read_books('a00000') }.to raise_error ArgumentError
        end
      end
    end

    describe '#reading_books' do
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
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.reading_books(user_id) }
        it { is_expected.not_to be_empty }
        it { is_expected.to include BookmeterScraper::Bookmeter::Book.new('Web API: The Good Parts', '水野貴明', [Time.local(2016, 2, 6)], 'http://bookmeter.com/b/4873116864', 'http://ecx.images-amazon.com/images/I/51GHwTNJgSL._SX230_.jpg'), BookmeterScraper::Bookmeter::Book.new('メタプログラミングRuby 第2版', 'PaoloPerrotta', [Time.local(2016, 2, 2)], 'http://bookmeter.com/b/4873117437', 'http://ecx.images-amazon.com/images/I/5102wwx0VzL._SX230_.jpg'), BookmeterScraper::Bookmeter::Book.new('ノンデザイナーズ・デザインブック [フルカラー新装増補版]', 'RobinWilliams', [Time.local(2015, 4, 28), Time.local(2016, 1, 10)], 'http://bookmeter.com/b/4839928401', 'http://ecx.images-amazon.com/images/I/41nvddaG9BL._SX230_.jpg') }
      end

      context 'taking valid user ID and reading books are not found' do
        include_context 'valid user ID'
        before do
          File.open('spec/fixtures/read_books_notfound.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklistnow')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.reading_books(user_id) }
        it { is_expected.to be_empty }
      end

      context 'when not logging in' do
        include_context 'valid user ID'
        subject { bookmeter.reading_books(user_id) }
        it { is_expected.to be_empty }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.new.reading_books(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '#tsundoku' do
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
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.tsundoku(user_id) }
        it { is_expected.not_to be_empty }
        it { is_expected.to include BookmeterScraper::Bookmeter::Book.new('Web API: The Good Parts', '水野貴明', [Time.local(2016, 2, 6)], 'http://bookmeter.com/b/4873116864', 'http://ecx.images-amazon.com/images/I/51GHwTNJgSL._SX230_.jpg'), BookmeterScraper::Bookmeter::Book.new('メタプログラミングRuby 第2版', 'PaoloPerrotta', [Time.local(2016, 2, 2)], 'http://bookmeter.com/b/4873117437', 'http://ecx.images-amazon.com/images/I/5102wwx0VzL._SX230_.jpg'), BookmeterScraper::Bookmeter::Book.new('ノンデザイナーズ・デザインブック [フルカラー新装増補版]', 'RobinWilliams', [Time.local(2015, 4, 28), Time.local(2016, 1, 10)], 'http://bookmeter.com/b/4839928401', 'http://ecx.images-amazon.com/images/I/41nvddaG9BL._SX230_.jpg') }
      end

      context 'taking valid user ID and tsundoku are not found' do
        include_context 'valid user ID'
        before do
          File.open('spec/fixtures/read_books_notfound.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklisttun')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.tsundoku(user_id) }
        it { is_expected.to be_empty }
      end

      context 'when not logging in' do
        include_context 'valid user ID'
        subject { bookmeter.tsundoku(user_id) }
        it { is_expected.to be_empty }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.new.tsundoku(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '#wish_list' do
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
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.wish_list(user_id) }
        it { is_expected.not_to be_empty }
        it { is_expected.to include BookmeterScraper::Bookmeter::Book.new('Web API: The Good Parts', '水野貴明', [Time.local(2016, 2, 6)], 'http://bookmeter.com/b/4873116864', 'http://ecx.images-amazon.com/images/I/51GHwTNJgSL._SX230_.jpg'), BookmeterScraper::Bookmeter::Book.new('メタプログラミングRuby 第2版', 'PaoloPerrotta', [Time.local(2016, 2, 2)], 'http://bookmeter.com/b/4873117437', 'http://ecx.images-amazon.com/images/I/5102wwx0VzL._SX230_.jpg'), BookmeterScraper::Bookmeter::Book.new('ノンデザイナーズ・デザインブック [フルカラー新装増補版]', 'RobinWilliams', [Time.local(2015, 4, 28), Time.local(2016, 1, 10)], 'http://bookmeter.com/b/4839928401', 'http://ecx.images-amazon.com/images/I/41nvddaG9BL._SX230_.jpg') }
      end

      context 'taking valid user ID and wish list are not found' do
        include_context 'valid user ID'
        before do
          File.open('spec/fixtures/read_books_notfound.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklistpre')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.wish_list(user_id) }
        it { is_expected.to be_empty }
      end

      context 'when not logging in' do
        include_context 'valid user ID'
        subject { bookmeter.wish_list(user_id) }
        it { is_expected.to be_empty }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.new.wish_list(user_id) }.to raise_error ArgumentError
        end
      end
    end
  end

  describe 'fetching following users and followers' do
    let(:bookmeter) { BookmeterScraper::Bookmeter.new }

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
    end

    describe '#followings' do
      before do
        File.open('spec/fixtures/followings.html') do |f|
          stub_request(:get, 'http://bookmeter.com/u/000000/favorite_user')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      context 'taking valid user ID and followers are found' do
        include_context 'valid user ID'
        before do
          bookmeter.log_in('mail', 'password')
        end

        describe 'a user' do
          subject { bookmeter.followings(user_id)[0] }
          it { is_expected.not_to be_nil }
          it { is_expected.to respond_to :name }
          it { is_expected.to respond_to :id }
          it { is_expected.to respond_to :uri }
        end

        describe 'users' do
          subject { bookmeter.followings(user_id) }
          it { is_expected.not_to be_empty }
          it { is_expected.to include BookmeterScraper::Bookmeter::User.new('test_user_2', '000001', 'http://bookmeter.com/u/000001'),
                                      BookmeterScraper::Bookmeter::User.new('test_user_3', '000002', 'http://bookmeter.com/u/000002'),
                                      BookmeterScraper::Bookmeter::User.new('test_user_4', '000003', 'http://bookmeter.com/u/000003'),
                                      BookmeterScraper::Bookmeter::User.new('test_user_5', '000004', 'http://bookmeter.com/u/000004'),
                                      BookmeterScraper::Bookmeter::User.new('test_user_6', '000005', 'http://bookmeter.com/u/000005') }
        end
      end

      context 'when not logging in' do
        include_context 'valid user ID'
        subject { bookmeter.followings(user_id) }
        it { is_expected.to be_empty }
      end
    end

    describe '#followings' do
      before do
        File.open('spec/fixtures/followers.html') do |f|
          stub_request(:get, 'http://bookmeter.com/u/000000/favorited_user')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      context 'taking valid user ID and following users are found' do
        include_context 'valid user ID'
        before do
          bookmeter.log_in('mail', 'password')
        end

        describe 'users' do
          subject { bookmeter.followers(user_id) }
          it { is_expected.not_to be_empty }
          it { is_expected.to include BookmeterScraper::Bookmeter::User.new('test_user_2', '000001', 'http://bookmeter.com/u/000001'),
                                      BookmeterScraper::Bookmeter::User.new('test_user_3', '000002', 'http://bookmeter.com/u/000002'),
                                      BookmeterScraper::Bookmeter::User.new('test_user_4', '000003', 'http://bookmeter.com/u/000003'),
                                      BookmeterScraper::Bookmeter::User.new('test_user_5', '000004', 'http://bookmeter.com/u/000004'),
                                      BookmeterScraper::Bookmeter::User.new('test_user_6', '000005', 'http://bookmeter.com/u/000005') }
        end
      end

      context 'when not logging in' do
        include_context 'valid user ID'
        subject { bookmeter.followers(user_id) }
        it { is_expected.to be_empty }
      end
    end
  end
end
