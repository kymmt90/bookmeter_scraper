require 'spec_helper'

RSpec.describe BookmeterScraper::Agent do
  describe '#log_in' do
    let(:agent) { BookmeterScraper::Agent.new }

    it 'raises ArgumentError' do
      expect { agent.log_in(nil) }.to raise_error ArgumentError
    end
  end
end
