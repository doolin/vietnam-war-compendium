#!/usr/bin/env ruby

require 'yaml'
require 'byebug'

file = YAML.load_file('./vietnam-timeline.yml')

byebug

puts file
