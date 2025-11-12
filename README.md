# Foobara::ShCliConnector

A command connector for Foobara that exposes commands via a shell command-line interface (CLI). This connector parses command-line arguments and routes them to Foobara commands, making it easy to build CLI tools from your Foobara commands.

<!-- TOC -->
* [Foobara::ShCliConnector](#foobarashcliconnector)
  * [Installation](#installation)
  * [Usage](#usage)
    * [Connecting multiple commands in a CLI script](#connecting-multiple-commands-in-a-cli-script)
    * [Single Command Mode](#single-command-mode)
  * [Development](#development)
  * [Contributing](#contributing)
    * [Reporting bugs or requesting features](#reporting-bugs-or-requesting-features)
    * [Contributing code](#contributing-code)
  * [License](#license)
<!-- TOC -->

## Installation

Typical stuff: add `gem "foobara-sh-cli-connector"` to your Gemfile or .gemspec file. Or even just
`gem install foobara-sh-cli-connector` if that's your jam.

## Usage

### Connecting multiple commands in a CLI script

```ruby
require "foobara/sh_cli_connector"

class Greet < Foobara::Command
  inputs do
    who :string, default: "World"
  end
  result :string

  def execute
    build_greeting

    greeting
  end

  attr_accessor :greeting

  def build_greeting = self.greeting = "Hello, #{who}!"
end

connector = Foobara::CommandConnectors::ShCliConnector.new
connector.connect(Greet)
connector.run
```

Then run your CLI script:

```
$ ./cli_demo.rb
Usage: cli_demo.rb [GLOBAL_OPTIONS] [ACTION] [COMMAND_OR_TYPE] [COMMAND_INPUTS]

Available actions:

  run, help, describe, manifest

Default action: run

Available commands:

 Greet
$ ./cli_demo.rb help Greet
Usage: cli_demo.rb [GLOBAL_OPTIONS] Greet [COMMAND_INPUTS]

Command inputs:

 -w, --who WHO                    Default: World

$ ./cli_demo.rb Greet
Hello, World!
$ ./cli_demo.rb Greet -w Fumiko
Hello, Fumiko!
```

### Single Command Mode

If you want to make a CLI script that only exposes one command, you can use single command mode:

```ruby
connector = Foobara::CommandConnectors::ShCliConnector.new(single_command_mode: Greet)
connector.run
```

Now you can run this without specifying the command name:

```
$ ./greet-cli --help
Usage: greet-cli [INPUTS]

Inputs:

 -w, --who WHO                    Default: World
$ ./greet-cli --who Barbara
Hello, Barbara!
```

## Development

## Contributing

I would love help with this and other Foobara gems! Feel free to hit me up at miles@foobara.com if you
think helping out would be fun or interesting! I have tasks for all experience levels and am often free
to pair on Foobara stuff.

### Reporting bugs or requesting features

Bug reports and feature requests can be made as github issues at https://github.com/foobara/sh-cli-connector

### Contributing code

You should be able to fork the repo, clone it locally, run `bundle` and then `rake` to run
the test suite and linter. Make your changes and push them up and open a PR! If you need any help please reach out and we're happy to help!

## License

foobara-sh-cli-connector is licensed under your choice of the Apache-2.0 license or the MIT license.
See [LICENSE.txt](LICENSE.txt) for more info about licensing.
