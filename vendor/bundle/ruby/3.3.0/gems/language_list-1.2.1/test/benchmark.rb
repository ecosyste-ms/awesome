#!/usr/bin/env ruby

require "benchmark"
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

time = Benchmark.measure do
  require 'language_list'
end
puts time