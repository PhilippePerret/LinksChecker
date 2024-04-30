#!/usr/bin/env ruby
# 

begin
  require_relative 'lib/required'
  LinksChecker.run
rescue Exception => e
  puts e.class
  if "".respond_to?(:rouge)
    puts e.message.rouge
    puts e.backtrace.join("\n").rouge
  else
    puts e.message
    puts e.backtrace.join("\n")
  end
end
