RSpec.describe Foobara::CommandConnectors::ShCliConnector do
  it "has a version number" do
    expect(Foobara::ShCliConnector::VERSION).to_not be_nil
  end

  context "When there is a connected command" do
    let(:command_connector) do
      Foobara::CommandConnectors::ShCliConnector.new
    end

    let(:command_class) do
      stub_class "SomeCommand", Foobara::Command do
        inputs do
          foo :string, default: "asdf"
          bar :integer, :required
          baz do
            foo :symbol
            bar :symbol
            baz :required do
              foo [:integer], :required
              bar :symbol
            end
          end
        end

        def execute
          { sum: baz[:baz][:foo].sum }
        end
      end
    end

    before do
      command_connector.connect(command_class)
    end

    context "when running the command with implicit #run with a formatter and inputs" do
      let(:argv) do
        [
          "-f yaml",
          "SomeCommand",
          "--foo",
          "some foo1",
          "--bar",
          "1",
          "--baz--foo",
          "some foo2",
          "--baz--bar",
          "some bar2",
          "--baz-baz-foo",
          "10",
          "11",
          "12",
          "--baz-baz-bar",
          "some bar3"
        ]
      end

      let(:outcome) { command_connector.run(argv) }

      it "runs the command" do
        expect(outcome).to be_success
        result = outcome.result

        expect(result).to eq("---\nsum: 33\n")
      end
    end
  end
end
