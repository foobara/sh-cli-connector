RSpec.describe Foobara::CommandConnectors::ShCliConnector do
  after do
    Foobara.reset_alls
  end

  it "has a version number" do
    expect(Foobara::ShCliConnector::VERSION).to_not be_nil
  end

  context "when there is a connected command" do
    let(:command_connector) do
      described_class.new(program_name: "test-cli", single_command_mode:, always_prefix_inputs:)
    end
    let(:single_command_mode) { false }
    let(:always_prefix_inputs) { false }

    let(:stdin) { StringIO.new }
    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }

    let(:inputs_proc) do
      some_model_class

      proc do
        foo :string, default: "asdf"
        bar :integer, :required, "just some attribute named bar"
        baz do
          foo :symbol
          bar :symbol
          baz :required do
            foo [:integer], :required, "Deeply nested foo!", default: [1, 2, 3]
            bar :symbol, one_of: [:foo, :bar, :baz, :"some bar3"]
          end
        end
        some_model SomeModel, :required
      end
    end

    let(:some_model_class) do
      stub_class "SomeModel", Foobara::Model do
        attributes do
          foo :integer
          bar :string, :required
          yo :string
        end
      end
    end

    let(:command_class) do
      ip = inputs_proc

      stub_class "SomeCommand", Foobara::Command do
        description "Just some command class"
        inputs(&ip)

        def execute
          { sum: baz&.[](:baz)&.[](:foo)&.sum }
        end
      end
    end

    let(:response) { command_connector.run(argv, stdin:, stdout:, stderr:) }

    def connect_command
      command_connector.connect(command_class)
    end

    before do
      connect_command
      allow(command_connector).to receive(:exit)
    end

    context "with no args" do
      let(:argv) { [] }

      it "performs the help action" do
        expect(response.request.action).to eq("help")
        # TODO: register help with the CLI serializer
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS]")
        expect(response.body).to include("Available actions:")
        expect(response.body).to include("--stdin")
      end
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
          "--baz-foo",
          "some foo2",
          "--baz-bar",
          "some bar2",
          "--baz-baz-foo",
          "10",
          "11",
          "12",
          "--baz-baz-bar",
          "some bar3",
          "--some-model-bar",
          "some model bar"
        ]
      end

      it "runs the command" do
        expect(response.body).to eq("---\n:sum: 33\n")
        expect(command_connector).to have_received(:exit).with(0)
      end

      context "when in single command mode" do
        let(:single_command_mode) { true }

        context "when argv doesn't contain the command" do
          let(:argv) do
            [
              "--foo",
              "some foo1",
              "--bar",
              "1",
              "--baz-foo",
              "some foo2",
              "--baz-bar",
              "some bar2",
              "--baz-baz-foo",
              "10",
              "11",
              "12",
              "--baz-baz-bar",
              "some bar3",
              "--some-model-bar",
              "some model bar"
            ]
          end

          it "runs the command" do
            expect(response.body).to eq("sum: 33\n")
            expect(command_connector).to have_received(:exit).with(0)
          end

          context "when passing a command to single_command_mode instead of true:" do
            let(:single_command_mode) { command_class }

            def connect_command
              # nothing to do here, connection happens automatically
            end

            it "connects the command automatically" do
              expect(response.body).to eq("sum: 33\n")
              expect(command_connector).to have_received(:exit).with(0)
            end

            context "when passing the command as an array of connect args" do
              let(:single_command_mode) { [command_class] }

              it "connects the command automatically" do
                expect(response.body).to eq("sum: 33\n")
                expect(command_connector).to have_received(:exit).with(0)
              end
            end
          end
        end

        context "when argv is only --help" do
          let(:argv) { ["--help"] }

          it "performs the help action" do
            expect(response.request.action).to eq("help")
            expect(response.body).to include("Usage: test-cli [INPUTS]")
          end
        end

        context "when connecting two commands" do
          let(:second_command_class) do
            stub_class "SomeOtherCommand", Foobara::Command
          end

          it "raises" do
            expect {
              command_connector.connect(second_command_class)
            }.to raise_error(Foobara::CommandConnectors::AlreadyHasAConnectedCommand)
          end
        end
      end

      context "when passing arguments via stdin" do
        let(:argv) { ["--stdin", "SomeCommand"] }

        let(:stdin) do
          StringIO.new('
            {
              "foo": "some foo1",
              "bar": 1,
              "baz": {
                "foo": "some foo2",
                "bar": "some bar2",
                "baz": {
                  "foo": [10, 11, 12],
                  "bar": "some bar3"
                }
              },
              "some_model": {
                "bar": "some model bar"
              }
            }
          ')
        end

        let(:format) { nil }

        it "runs the command" do
          expect(response.body).to eq("---\n:sum: 33\n")
          expect(stdout.string).to eq(response.body)
          expect(command_connector).to have_received(:exit).with(0)
        end

        context "when json format" do
          let(:argv) { ["-f", format, "--stdin", "SomeCommand"] }
          let(:format) { "json" }

          it "runs the command" do
            expect(response.body).to eq('{"sum":33}')
            expect(stdout.string.chomp).to eq(response.body)
            expect(command_connector).to have_received(:exit).with(0)
          end
        end
      end

      context "when there's additional bad arguments" do
        let(:argv) { ["SomeCommand", "--bar", "10", "extra junk"] }

        it "is an error" do
          expect(response.body).to eq("Unexpected argument: extra junk")
          expect(command_connector).to have_received(:exit).with(6)
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

        let(:argv) { ["SomeCommand", "--foo", "1", "2"] }

        it "works all the way down" do
          expect(response.status).to be(0)
          expect(response.body).to eq("sum: 3\n")
          expect(command_connector).to have_received(:exit).with(0)
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

        it "is true" do
          expect(response.command.inputs[:flag]).to be(true)
        end

        context "with a default" do
          let(:inputs_proc) do
            proc do
              baz :string
              flag :boolean, default: true
            end
          end

          context "when setting" do
            it "doesn't have a flag for the default" do
              expect(response.error.message).to eq("Unexpected argument: -f")
            end
          end

          context "when unsetting" do
            let(:argv) { ["SomeCommand", "--no-flag"] }

            it "is false as normal" do
              expect(response.command.inputs[:flag]).to be(false)
            end
          end
        end

        context "when turning flag off" do
          let(:argv) { ["SomeCommand", "--no-flag"] }

          it "is false when using --no- form" do
            expect(response.command.inputs[:flag]).to be(false)
          end
        end
      end
    end

    context "when using help action through a switch" do
      let(:argv) { ["--help"] }

      it "sets the help action" do
        expect(response.request.action).to eq("help")
        # TODO: register help with the CLI serializer
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS]")
        expect(response.body).to include("Available actions:")
        expect(response.body).to include("--stdin")
      end
    end

    context "when asking for help with a command" do
      let(:argv) { ["help", "SomeCommand"] }

      it "gives help text for the command" do
        expect(response.status).to be(0)
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS] SomeCommand")
        expect(response.body).to include("Just some command class")
        expect(response.body).to match(/-f,\s*--foo FOO\s*Default: "asdf"/)
        expect(response.body).to match(/-y,\s*--yo YO/)
        expect(response.body).to match(/-b,\s*--bar BAR\s*just some attribute named bar\. Required/)
        expect(response.body).to include("One of: foo, bar, baz, some bar3")
      end

      context "when always including prefixes" do
        let(:always_prefix_inputs) { true }

        it "gives help text for the command with all inputs including prefixes" do
          expect(response.status).to be(0)
          expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS] SomeCommand")
          expect(response.body).to include("Just some command class")
          expect(response.body).to match(/-f,\s*--foo FOO\s*Default: "asdf"/)
          expect(response.body).to match(/-y,\s*--some-model-yo SOME_MODEL_YO/)
          expect(response.body).to match(/-b,\s*--bar BAR\s*just some attribute named bar\. Required/)
          expect(response.body).to include("One of: foo, bar, baz, some bar3")
        end
      end
    end

    context "when asking for help with a command that doesn't exist" do
      let(:argv) { ["help", "SomeCommandThatDoesntExist"] }

      it "gives general help text with a warning about not finding the command" do
        expect(response.status).to be(0)
        expect(response.body).to include("WARNING: Unexpected argument: SomeCommandThatDoesntExist")
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS] [ACTION] [COMMAND_OR_TYPE] [COMMAND_INPUTS]")
        expect(response.body).to include("Available actions:")
        expect(response.body).to include("--help")
      end
    end

    context "when asking for help with the run action" do
      let(:argv) { ["help", "run"] }

      it "gives help for the run action" do
        expect(response.status).to be(0)
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS] run COMMAND_NAME [COMMAND_INPUTS]")
        expect(response.body).to_not include("Available actions:")
        expect(response.body).to include("--help")
      end
    end

    context "when asking for help with the describe action" do
      let(:argv) { ["help", "describe"] }

      it "gives help for the describe action" do
        expect(response.status).to be(0)
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS] describe COMMAND_OR_TYPE_NAME")
        expect(response.body).to_not include("Available actions:")
        expect(response.body).to include("--help")
      end
    end

    context "when asking for help with the ping action" do
      let(:argv) { ["help", "ping"] }

      it "gives help for the ping action" do
        expect(response.status).to be(0)
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS] ping")
        expect(response.body).to_not include("Available actions:")
        expect(response.body).to include("--help")
      end
    end

    context "when asking for help with the query_git_commit_info action" do
      let(:argv) { ["help", "query_git_commit_info"] }

      it "gives help for the query_git_commit_info action" do
        expect(response.status).to be(0)
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS] query_git_commit_info")
        expect(response.body).to_not include("Available actions:")
        expect(response.body).to include("--help")
      end
    end

    context "when asking for help with the help action" do
      let(:argv) { ["help", "help"] }

      it "gives help for the help action" do
        expect(response.status).to be(0)
        expect(response.body).to include("Usage: test-cli [GLOBAL_OPTIONS] help [ACTION_OR_COMMAND]")
        expect(response.body).to_not include("Available actions:")
        expect(response.body).to include("--help")
      end
    end

    context "when asking for a list of commands" do
      let(:argv) { ["list"] }

      it "gives a list of commands" do
        expect(response.status).to be(0)
        expect(response.body).to eq("SomeCommand\n")
        expect(response.request.action).to eq("list")
      end

      context "when verbose" do
        let(:argv) { ["list", "--verbose"] }

        it "gives commands and their descriptions" do
          expect(response.status).to be(0)
          expect(response.body).to eq("SomeCommand Just some command class\n")
          expect(response.request.action).to eq("list")
        end
      end
    end

    context "when asking for a list of commands via -l" do
      let(:argv) { ["-l"] }

      it "gives a list of commands" do
        expect(response.status).to be(0)
        expect(response.body).to eq("SomeCommand\n")
        expect(response.request.action).to eq("list")
      end

      context "when verbose" do
        let(:argv) { ["-l", "--verbose"] }

        it "gives commands and their descriptions" do
          expect(response.status).to be(0)
          expect(response.body).to eq("SomeCommand Just some command class\n")
          expect(response.request.action).to eq("list")
        end
      end
    end

    context "when running with --atomic" do
      let(:argv) { ["--atomic", "run", "SomeCommand", "--bar", "5", "--some-model-bar", "some bar"] }

      it "sets an atomic serializer" do
        expect(response.status).to be(0)
        expect(command_connector).to have_received(:exit).with(0)
        expect(response.request.serializers).to include("atomic")
      end
    end

    context "when running with --aggregate" do
      let(:argv) { ["--aggregate", "run", "SomeCommand", "--bar", "5", "--some-model-bar", "some bar"] }

      it "sets an aggregate serializer" do
        expect(response.status).to be(0)
        expect(command_connector).to have_received(:exit).with(0)
        expect(response.request.serializers).to include("aggregate")
      end
    end

    context "when running with --record-store" do
      let(:argv) { ["--record-store", "run", "SomeCommand", "--bar", "5", "--some-model-bar", "some bar"] }

      it "sets a record store serializer" do
        expect(response.status).to be(0)
        expect(command_connector).to have_received(:exit).with(0)
        expect(response.request.serializers).to include("record_store")
      end
    end

    context "when setting entity depth to record-store" do
      let(:argv) do
        ["--entity-depth", "record-store", "run", "SomeCommand", "--bar", "5", "--some-model-bar", "some bar"]
      end

      it "sets a record store serializer" do
        expect(response.status).to be(0)
        expect(command_connector).to have_received(:exit).with(0)
        expect(response.request.serializers).to include("record_store")
      end
    end

    context "when command has no inputs" do
      let(:command_class) do
        stub_class "SomeCommand", Foobara::Command do
          description "Just some command class"

          def execute
            "simple command"
          end
        end
      end

      let(:argv) { ["run", "SomeCommand"] }

      it "runs it" do
        expect(response.status).to be(0)
        expect(command_connector).to have_received(:exit).with(0)
      end
    end

    context "when setting --verbose" do
      let(:argv) { ["--verbose"] }

      it "sets the verbose flag" do
        expect(response.request.globalish_options[:verbose]).to be(true)
      end
    end

    context "when not giving a command to run" do
      let(:argv) { ["run"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(command_connector).to have_received(:exit).with(6)
        expect(response.body).to match("Missing command to run")
      end
    end

    context "when giving bad global options" do
      let(:argv) { ["--bad", "option", "SomeCommand", "--foo", "asdf"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(command_connector).to have_received(:exit).with(6)
        expect(response.body).to match("Found invalid option --bad")
      end
    end

    context "when giving two actions" do
      let(:argv) { ["run", "run", "SomeCommand", "--foo", "asdf"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(command_connector).to have_received(:exit).with(6)
        expect(response.body).to match("Could not find command")
      end
    end

    context "with describe action with no target" do
      let(:argv) { ["describe"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(command_connector).to have_received(:exit).with(6)
        expect(response.body).to match("Missing command or type to describe")
      end
    end

    context "with a bunch of unexpected positional arguments" do
      let(:argv) { ["SomeCommand", "10", "11", "12"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(command_connector).to have_received(:exit).with(6)
        expect(response.body).to match("Unexpected argument: 10")
      end
    end

    context "with a bad serializer format" do
      let(:argv) { ["-f", "asdf", "SomeCommand", "--foo", "asdf"] }

      it "is an error" do
        expect(response.status).to be(6)
        expect(command_connector).to have_received(:exit).with(6)
        expect(response.body).to match("Unknown format: asdf")
      end
    end

    context "when there's an error" do
      let(:argv) { ["SomeCommand", "--bar", "asdf", "--some-model-bar", "some bar"] }

      it "is an error" do
        expect(response.status).to be(1)
        expect(command_connector).to have_received(:exit).with(1)
        expect(response.body).to match('At bar: Cannot cast "asdf"')
      end
    end
  end
end
