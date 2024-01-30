RSpec.describe Foobara::CommandConnectors::ShCliConnector do
  it "has a version number" do
    expect(Foobara::ShCliConnector::VERSION).to_not be_nil
  end

  context "when there is a connected command" do
    let(:command_connector) do
      described_class.new
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

    let(:response) { command_connector.run(argv) }

    before do
      command_connector.connect(command_class)
    end

    context "when running the command with implicit #run with a formatter and inputs" do
      let(:argv) do
        [
          "-f",
          "yaml",
          "SomeCommand",
          "--foo",
          "some foo1",
          "--bar",
          "1",
          "--baz--foo",
          "some foo2",
          "--baz--bar",
          "some bar2",
          "--baz--baz--foo",
          "10",
          "11",
          "12",
          "--baz--baz--bar",
          "some bar3"
        ]
      end

      it "runs the command" do
        expect(response.status).to be(0)
        expect(response.body).to eq("---\n:sum: 33\n")
      end
    end

    context "when not giving a command to run" do
      let(:argv) { ["run"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(response.body).to match("Missing command to run")
      end
    end
  end
end
