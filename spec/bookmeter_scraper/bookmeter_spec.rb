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
      context 'valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.reading_books_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklistnow" }
      end

      context 'invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.reading_books_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.tsundoku_uri' do
      context 'valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.tsundoku_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklisttun" }
      end

      context 'invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.tsundoku_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.wish_list_uri' do
      context 'valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.wish_list_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklistpre" }
      end

      context 'invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.wish_list_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.followings_uri' do
      context 'valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.followings_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/favorite_user" }
      end

      context 'invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.followings_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '.followers_uri' do
      context 'valid user ID' do
        include_context 'valid user ID'
        subject { BookmeterScraper::Bookmeter.followers_uri(user_id) }
        it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/favorited_user" }
      end

      context 'invalid user ID' do
        include_context 'invalid user ID'
        it 'raises ArgumentError' do
          expect { BookmeterScraper::Bookmeter.followers_uri(user_id) }.to raise_error ArgumentError
        end
      end
    end
  end

  describe '.log_in' do
    let(:bookmeter) { BookmeterScraper::Bookmeter.log_in('mail', 'password') }

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

    context 'valid mail / password' do
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

    context 'invalid mail / password' do
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

  describe 'fetching books methods' do
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
      context 'found' do
        include_context 'valid user ID'
        before do
          File.open('spec/fixtures/read_books.html') do |f|
            stub_request(:any, 'http://bookmeter.com/u/000000/booklist')
              .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
          end
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.read_books(user_id) }
        it { is_expected.not_to be_empty }
      end

      context 'not found' do
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

      context 'found' do
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
      end

      context 'not found' do
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

      context 'found' do
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
      end

      context 'not found' do
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

      context 'not logging in' do
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

      context 'found' do
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
      end

      context 'not found' do
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

  describe 'fetching followings / followers methods' do
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

      context 'found' do
        include_context 'valid user ID'
        before do
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.followings(user_id) }
        it { is_expected.not_to be_empty }
      end
    end

    describe '#followings' do
      before do
        File.open('spec/fixtures/followers.html') do |f|
          stub_request(:get, 'http://bookmeter.com/u/000000/favorited_user')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      context 'found' do
        include_context 'valid user ID'
        before do
          bookmeter.log_in('mail', 'password')
        end
        subject { bookmeter.followers(user_id) }
        it { is_expected.not_to be_empty }
      end
    end
  end
end
