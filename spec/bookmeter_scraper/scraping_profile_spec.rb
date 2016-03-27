require 'spec_helper'

RSpec.describe BookmeterScraper::Scraper do
  describe '#fetch_profile' do
    let!(:agent) { BookmeterScraper::Agent.new }
    let(:scraper) { BookmeterScraper::Scraper.new(agent) }
    let(:profile) { scraper.fetch_profile('000000') }

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

    context 'taking invalid arguments' do
      let!(:agent) { BookmeterScraper::Agent.new }
      let(:scraper) { BookmeterScraper::Scraper.new(agent) }

      it 'raises ArgumentError' do
        expect { scraper.fetch_profile('a00000') }.to raise_error ArgumentError
      end

      it 'raises ScraperError' do
        expect { scraper.fetch_profile('000000', nil) }.to raise_error BookmeterScraper::ScraperError
      end
    end
  end
end
