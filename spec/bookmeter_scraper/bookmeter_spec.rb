require 'spec_helper'

RSpec.describe BookmeterScraper::Bookmeter do
  describe '.mypage_uri' do
    let(:user_id) { '000000' }
    let(:invalid_user_id) { '00a000' }

    describe 'valid user ID' do
      subject { BookmeterScraper::Bookmeter.mypage_uri(user_id) }
      it { is_expected.to eq "http://bookmeter.com/u/#{user_id}" }
    end

    describe 'invalid user ID' do
      it 'raises ArgumentError' do
        expect { BookmeterScraper::Bookmeter.mypage_uri(invalid_user_id) }.to raise_error ArgumentError
      end
    end
  end

  describe '.read_books_uri' do
    let(:user_id) { '000000' }
    let(:invalid_user_id) { '00a000' }

    describe 'valid user ID' do
      subject { BookmeterScraper::Bookmeter.read_books_uri(user_id) }
      it { is_expected.to eq "http://bookmeter.com/u/#{user_id}/booklist" }
    end

    describe 'invalid user ID' do
      it 'raises ArgumentError' do
        expect { BookmeterScraper::Bookmeter.read_books_uri(invalid_user_id) }.to raise_error ArgumentError
      end
    end
  end

  describe '.log_in' do
    context 'valid mail / password' do
      let(:bookmeter) { BookmeterScraper::Bookmeter.log_in('mail', 'valid') }

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
      let(:bookmeter) { BookmeterScraper::Bookmeter.log_in('mail', 'invalid') }

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
    context 'valid mail / password' do
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

    context 'invalid mail / password' do
      let(:bookmeter) { BookmeterScraper::Bookmeter.new }

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

    context 'complete profile' do
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

    context 'imcomplete profile' do
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
end
