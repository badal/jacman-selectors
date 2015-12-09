#!/usr/bin/env ruby
# encoding: utf-8
#
# File: version.rb
# Created: 09 October 2015
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors
    MAJOR = 1
    MINOR = 4
    TINY = 0

    VERSION = [MAJOR, MINOR, TINY].join('.')
  end
end
