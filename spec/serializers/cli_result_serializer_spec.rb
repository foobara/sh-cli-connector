RSpec.describe Foobara::CommandConnectors::ShCliConnector::Serializers::CliResultSerializer do
  subject { serializer.serialize(object) }

  let(:serializer) { described_class.new(nil) }

  context "when object is a string" do
    let(:object) { "foo" }

    it { is_expected.to eq("foo") }
  end

  context "when object is an array" do
    let(:object) { ["foo", "bar", 1] }

    it {
      is_expected.to eq(
        <<~OUTPUT
          "foo",
          "bar",
          1
        OUTPUT
      )
    }
  end

  context "when object is a hash with an array attribute" do
    let(:object) do
      {
        a: [
          { b: [:foo, :bar] },
          10,
          [1, 2, 3]
        ],
        b: :baz,
        c: {
          d: "e"
        }
      }
    end

    it {
      is_expected.to eq(
        <<~OUTPUT
          a: [
            {
              b: [
                :foo,
                :bar
              ]
            },
            10,
            [
              1,
              2,
              3
            ]
          ],
          b: :baz,
          c: {
            d: "e"
          }
        OUTPUT
      )
    }
  end
end
