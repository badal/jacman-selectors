#!/usr/bin/env ruby
# encoding: utf-8
#
# File: selectors.rb
# Created: 09 October 2015
#
# (c) Michel Demazure <michel@demazure.com>

require 'yaml'

module JacintheManagement
  module Selectors
    @all = []

    def self.all
      @all
    end

    def self.<<(selector)
      @all << selector
    end

    DIRECTORY = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'source_files'))
  end
end

require_relative 'selectors/version.rb'
require_relative 'selectors/selector.rb'


