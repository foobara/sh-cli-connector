RSpec.describe Foobara::CommandConnectors::ShCliConnector do
  it "has a version number" do
    expect(Foobara::ShCliConnector::VERSION).to_not be_nil
  end

  context "when there is a connected command" do
    let(:command_connector) do
      described_class.new
    end

    let(:inputs_proc) do
      proc do
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
    end

    let(:command_class) do
      ip = inputs_proc

      stub_class "SomeCommand", Foobara::Command do
        inputs(&ip)

        def execute
          { sum: baz&.[](:baz)&.[](:foo)&.sum }
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
          "--input-format",
          "yaml",
          "--output-format",
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

      context "when there's additional bad arguments" do
        let(:argv) { ["SomeCommand", "--bar", "10", "extra junk"] }

        it "is an error" do
          expect(response.status).to be(6)
          expect(response.body).to eq("Unexpected argument: extra junk")
        end
      end

      context "when nested attributes are required all the way down" do
        let(:inputs_proc) do
          proc do
            flag :boolean
            baz :required do
              baz :required do
                foo [:integer], :required
              end
            end
          end
        end

        let(:argv) { ["SomeCommand", "--baz--baz--foo", "1", "2"] }

        it "works all the way down" do
          expect(response.status).to be(0)
          expect(response.body).to eq("---\n:sum: 3\n")
        end
      end

      context "with a boolean flag" do
        let(:inputs_proc) do
          proc do
            baz :string
            flag :boolean
          end
        end

        let(:argv) { ["SomeCommand", "-f"] }

        it "defaults it to true when not giving a value" do
          expect(response.command.inputs[:flag]).to be(true)
        end
      end
    end

    context "when using help action through a switch" do
      let(:argv) { ["--help"] }

      it "sets the help action" do
        expect(response.request.action).to eq("help")
        # TODO: register help with the CLI serializer
        expect(response.body).to match("helping!!")
      end
    end

    context "when not giving a command to run" do
      let(:argv) { ["run"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(response.body).to match("Missing command to run")
      end
    end

    context "when giving bad global options" do
      let(:argv) { ["--bad", "option", "SomeCommand", "--foo", "asdf"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(response.body).to match("Found invalid option --bad")
      end
    end

    context "when giving two actions" do
      let(:argv) { ["run", "run", "SomeCommand", "--foo", "asdf"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(response.body).to match("Could not find command")
      end
    end

    context "with describe action with no target" do
      let(:argv) { ["describe"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(response.body).to match("Missing command or type to describe")
      end
    end

    context "with a bunch of unexpected positional arguments" do
      let(:argv) { %w[SomeCommand 10 11 12] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(response.body).to match("Unexpected argument: 10")
      end
    end

    context "with a bad serializer format" do
      let(:argv) { ["-f", "asdf", "SomeCommand", "--foo", "asdf"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(response.body).to match("Unknown format: asdf")
      end
    end

    context "when there's an error" do
      let(:argv) { ["SomeCommand", "--bar", "asdf"] }

      it "is an error" do
        expect(response.status).to be(1)
        expect(response.body).to match('At bar: Cannot cast "asdf"')
      end
    end
  end
end
