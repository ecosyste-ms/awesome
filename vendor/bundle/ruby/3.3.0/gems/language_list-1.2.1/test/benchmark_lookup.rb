#!/usr/bin/env ruby

require "benchmark"
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'language_list'


count = LanguageList::ALL_LANGUAGES.count

time = Benchmark.measure do
   

   1000.times do 
   	target = LanguageList::ALL_LANGUAGES[rand(count)]

    LanguageList::LanguageInfo.find_by_name(target.name)
    LanguageList::LanguageInfo.find(target.iso_639_3)
   end
end
puts time
