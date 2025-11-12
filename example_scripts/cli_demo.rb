#!/usr/bin/env ruby

require_relative "greet"
require "foobara/sh_cli_connector"

connector = Foobara::CommandConnectors::ShCliConnector.new
connector.connect(Greet)
connector.run
