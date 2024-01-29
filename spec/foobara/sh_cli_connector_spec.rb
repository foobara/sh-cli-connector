RSpec.describe Foobara::ShCliConnector do
  it "has a version number" do
    expect(Foobara::ShCliConnector::VERSION).to_not be_nil
  end

  it "opt parser" do
    opts = OptionParser.new
    opts.raise_unknown = true
    opts.on("-f FOO", "--foo FOO", "FOOOOOO!!!") do |foo|
      puts "parsed foo: #{foo}"
    end
    opts.on("-b [BAR]") do |bar|
      binding.pry
      puts "parsed bar: #{bar}"
    end

    args = ["-f asdfd"]
    args = ["-f", "adf", "-f", "2", "x", "-c", "hi", "-d"]
    args = ["-b"]

    begin
      $stop = true
      out = opts.order!(args) do |nonopt|
        puts "nonopt: #{nonopt}"
        opts.terminate(nonopt)
      end
      puts "out: #{out}"
      binding.pry
    rescue => e
      puts "in rescue: #{e}"
      binding.pry
    end
  end
end

# how do we want this to work??
# prog(org) [globalish_opts] org:domain:command [command opts]
# globalish opts parser
# command opts parser (each command has a different one of these...)
# globallihs args...
# --help
# --version
# --describe
# --manifest ? (maybe describe with no args?)
