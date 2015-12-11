#!/usr/bin/env ruby
# encoding: utf-8
#
# File: selectors.rb
# Created: 09 October 2015
#
# (c) Michel Demazure <michel@demazure.com>

require 'yaml'

require_relative 'selectors/version.rb'
require_relative 'selectors/formatters.rb'
require_relative 'selectors/table.rb'
require_relative 'selectors/selector.rb'

module JacintheManagement
  # global methods for the Selector GUI
  module Selectors
    @all = []

    # @return [Array<Selector>] all registered selectors
    def self.all
      @all
    end

    # @param [Selector] selector selector to be registered
    def self.<<(selector)
      @all << selector
    end

    # @return [Array<Selector>] all registered selectors
    # @param [Path] directory where to look for selector files
    # @param [String] extension extension of the files, including the initial dot
    def self.add_from_directory(directory, extension = '')
      Dir.glob("#{directory}/**/*#{extension}").each do |path|
        @all << Selector.from_file(path)
      end
    end
  end
end
