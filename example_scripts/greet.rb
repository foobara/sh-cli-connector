require "foobara"

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
