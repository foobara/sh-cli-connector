RSpec.describe Foobara::CommandConnectors::ShCliConnector::Serializers::CliTabularSerializer do
  let(:result) { serializer.serialize(table) }
  let(:terminal_width) { 80 }

  let(:serializer) { described_class.new(terminal_width:) }

  let(:table) do
    [
      %w[foofoo barbar bazbaz]
    ]
  end

  it "serializes the table" do
    expect(result).to eq(
      <<~OUTPUT
        foofoo barbar bazbaz
      OUTPUT
    )
  end

  context "when bigger than terminal size" do
    let(:terminal_width) { 20 }

    it "serializes the table" do
      expect(result).to eq(
        <<~OUTPUT
          foof- barb- bazbaz
          oo    ar
        OUTPUT
      )
    end
  end
end
