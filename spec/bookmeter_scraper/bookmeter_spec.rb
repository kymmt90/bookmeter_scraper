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
