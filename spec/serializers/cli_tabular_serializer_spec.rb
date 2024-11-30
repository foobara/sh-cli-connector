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

    context "when last column content is too long" do
      let(:table) do
        [
          ["a", "b", "This is way too loooooooooooooooooooooooong to fit on one line."]
        ]
      end

      it "serializes the table" do
        expect(result).to eq(
          <<~OUTPUT
            a b This is way too
                loooooooooooooooo-
                oooooooong
                to fit on one lin-
                e.
          OUTPUT
        )
      end
    end

    context "when using indentation" do
      let(:serializer) { described_class.new(terminal_width:, indent: 2) }

      it "serializes the table" do
        expect(result).to eq(
          "  foof- barb- bazbaz\n  oo    ar\n"
        )
      end
    end
  end
end
