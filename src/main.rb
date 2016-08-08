#!/usr/bin/env ruby
require          'optparse'
require_relative 'parser'
require_relative 'generators/sklibc'
require_relative 'generators/yaml'

# Required to run
options = {
  generators: [],
  src: nil
}

# Options parse block
opt_parser = OptionParser.new do |opts|
  # Generators we can use
  avaliable_gens =
    Generators.constants
              .select { |c| Class === Generators.const_get(c) }
              .map { |g| [g.upcase, Generators.const_get(g)] }
              .to_h
  # Setup
  help = <<-EOS
Usage: parse.rb --from /path/to/splashkit/coresdk/src/coresdk[/file.h]
                --to GENERATOR[,GENERATOR ... ]
EOS
  opts.banner = help
  opts.separator ''
  opts.separator 'Required:'
  # Source file
  help = <<-EOS
Source header file or SplashKit CoreSDK directory
EOS
  opts.on('-f', '--from SOURCE', help) do |file|
    options[:src] = file
  end
  # To [using generator]
  help = <<-EOS
Comma separated list of generators to run on the file(s).
EOS
  opts.on('-t', '--to GENERATOR[,GENERATOR ... ]', help) do |gens|
    parsed_gens = gens.split(',')
    options[:generators] = parsed_gens.map do |gen|
      gen_class = avaliable_gens[gen.upcase.to_sym]
      if gen_class.nil?
        raise OptionParser::InvalidOption.new "#{gen} - Unknown generator #{gen}"
      end
      gen_class
    end
  end
  opts.separator ''
  opts.separator 'Generators:'
  avaliable_gens.keys.each { |gen| opts.separator "    * #{gen}"}
end
# Parse block
begin
  opt_parser.parse!
  mandatory = [:generators, :src]
  missing = mandatory.select{ |param| options[param].nil? }
  raise OptionParser::MissingArgument.new "Arguments missing" unless missing.empty?
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts opt_parser
  exit 1
end
# Run block
begin
  raise 'headerdoc2html is not installed!' unless Parser.headerdoc_installed?
  parsed = Parser.parse(options[:src])
  options[:generators].each do | generator_class |
    puts generator_class.new(parsed).execute
  end
rescue => e
  puts $!.to_s
  exit 1
end
