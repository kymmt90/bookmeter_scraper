require 'spec_helper'

RSpec.describe BookmeterScraper::Scraper do
  shared_context 'valid user ID' do
    let(:user_id) { '000000' }
  end

  shared_context 'invalid user ID' do
    let(:user_id) { '00a000' }
  end

  describe 'scraping users' do
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
          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        describe 'users' do
          subject { scraper.get_followings(user_id) }
          it { is_expected.not_to be_empty }
          it { is_expected.to include \
            BookmeterScraper::Scraper::User.new('test_user_2', '000001', 'http://bookmeter.com/u/000001'),
            BookmeterScraper::Scraper::User.new('test_user_3', '000002', 'http://bookmeter.com/u/000002'),
            BookmeterScraper::Scraper::User.new('test_user_4', '000003', 'http://bookmeter.com/u/000003'),
            BookmeterScraper::Scraper::User.new('test_user_5', '000004', 'http://bookmeter.com/u/000004'),
            BookmeterScraper::Scraper::User.new('test_user_6', '000005', 'http://bookmeter.com/u/000005')
          }
        end
      end

      context 'when not logging in' do
        include_context 'valid user ID'

        before do
          scraper.agent = agent
        end

        subject { scraper.get_followings(user_id) }
        it { is_expected.to be_empty }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'

        it 'raises ArgumentError' do
          expect { scraper.get_followings(user_id) }.to raise_error ArgumentError
        end
      end
    end

    describe '#followers' do
      before do
        File.open('spec/fixtures/followers.html') do |f|
          stub_request(:get, 'http://bookmeter.com/u/000000/favorited_user')
            .to_return(body: f.read, headers: { 'Content-Type' => 'text/html' })
        end
      end

      context 'taking valid user ID and following users are found' do
        include_context 'valid user ID'

        before do
          configuration = BookmeterScraper::Configuration.new.tap do |c|
            c.mail, c.password = 'mail', 'password'
          end
          agent.log_in(configuration)
          scraper.agent = agent
        end

        describe 'users' do
          subject { scraper.get_followers(user_id) }
          it { is_expected.not_to be_empty }
          it { is_expected.to include \
            BookmeterScraper::Scraper::User.new('test_user_2', '000001', 'http://bookmeter.com/u/000001'),
            BookmeterScraper::Scraper::User.new('test_user_3', '000002', 'http://bookmeter.com/u/000002'),
            BookmeterScraper::Scraper::User.new('test_user_4', '000003', 'http://bookmeter.com/u/000003'),
            BookmeterScraper::Scraper::User.new('test_user_5', '000004', 'http://bookmeter.com/u/000004'),
            BookmeterScraper::Scraper::User.new('test_user_6', '000005', 'http://bookmeter.com/u/000005')
          }
        end
      end

      context 'when not logging in' do
        include_context 'valid user ID'

        before do
          scraper.agent = agent
        end

        subject { scraper.get_followers(user_id) }
        it { is_expected.to be_empty }
      end

      context 'taking invalid user ID' do
        include_context 'invalid user ID'

        it 'raises ArgumentError' do
          expect { scraper.get_followers(user_id) }.to raise_error ArgumentError
        end
      end
    end
  end
end
