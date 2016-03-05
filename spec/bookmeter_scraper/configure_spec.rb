require 'spec_helper'

RSpec.describe BookmeterScraper::Configuration do
  let(:valid_mail)     { 'example@example.com' }
  let(:valid_password) { 'password' }

  shared_context 'valid configuration file' do
    let(:configuration_filename) { 'spec/fixtures/config.yml' }
  end

  shared_context 'invalid configuration file' do
    let(:configuration_filename) { 'spec/fixtures/invalid_config.yml' }
  end

  describe '#mail' do
    context 'taking valid configuration file' do
      include_context 'valid configuration file'

      let(:configuration) { BookmeterScraper::Configuration.new(configuration_filename) }
      subject { configuration.mail }
      it { is_expected.to eq valid_mail }
    end

    context 'taking invalid configuration file' do
      include_context 'invalid configuration file'

      let(:configuration) { BookmeterScraper::Configuration.new(configuration_filename) }
      subject { configuration.mail }
      it 'raises ConfigurationError' do
        expect { BookmeterScraper::Configuration.new(configuration_filename) }.to raise_error BookmeterScraper::ConfigurationError
      end
    end
  end

  describe '#password' do
    context 'taking valid configuration file' do
      include_context 'valid configuration file'

      let(:configuration) { BookmeterScraper::Configuration.new(configuration_filename) }
      subject { configuration.password }
      it { is_expected.to eq valid_password }
    end

    context 'taking invalid configuration file' do
      include_context 'invalid configuration file'

      let(:configuration) { BookmeterScraper::Configuration.new(configuration_filename) }
      subject { configuration.password }
      it 'raises ConfigurationError' do
        expect { BookmeterScraper::Configuration.new(configuration_filename) }.to raise_error BookmeterScraper::ConfigurationError
      end
    end
  end
end
