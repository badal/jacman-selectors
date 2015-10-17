#!/usr/bin/env ruby
# encoding: utf-8
#
# File: selectors.rb
# Created: 09 October 2015
#
# (c) Michel Demazure <michel@demazure.com>

require 'yaml'

require_relative 'selectors/version.rb'
require_relative 'selectors/selector.rb'

module JacintheManagement
  module Selectors

    @all = []

    def self.all
      @all
    end

    def self.<<(selector)
      @all << selector
    end

    def self.add_from_file(filename)
      @all << Selector.from_file(File.join(DIRECTORY, filename))
    end

    def self.add_from_directory(directory, extension = '')
      Dir.glob("#{directory}/**/*#{extension}").each do |path|
        @all << Selector.from_file(path)
      end
    end
  end
end


