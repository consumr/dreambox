#!/usr/bin/env ruby
require_relative '../templates/class_config.rb'

# Tests class
#
# This class tests an array of assertions, each a hash with a description expected
# value and actual value. The outcome of each test is saved, then printed to stdout
# upon completion of all tests.
#
class Tests
  attr_accessor :the, :assertions

  def initialize(opts)
    @the = {}
    @assertions = []

    opts.each do |opt|
      basename = File.basename(opt, File.extname(opt))
      @the[basename] = Config.new(opt)
    end
  end

  def print_stats
    puts ''
    puts "==> #{@passing.length}/#{@tests_run} tests passed".bold.green

    if @failing.length > 0
      puts "==> #{@failing.length}/#{@tests_run} tests failed\n".bold.red
      @failing.each do |message|
        puts "#{message[:name]}\n"
        printf "Expected  => %s\n".yellow, message[:expected]
        printf "Actual    => %s\n\n".red, message[:actual]
      end
    end
  end

  def run
    @failing = []
    @passing = []
    @tests_run = 0

    @assertions.each do |test|
      # Test assert condition
      condition_met =
        if false == test['assert']
          ! test['expect'].eql? test['actual']
        else
          test['expect'].eql? test['actual']
        end

      # Test for equal values
      if condition_met
        @passing.push("`#{test['name']}` value")
      else
        message = { name: test['name'], expected: test['expect'], actual: test['actual'] }
        @failing.push(message)
      end
      @tests_run += 1
    end
  end
end
