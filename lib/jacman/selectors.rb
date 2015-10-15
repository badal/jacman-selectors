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

    DIRECTORY = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'source_files'))
  end

  Selectors.add_from_file('pour_essai')
  Selectors.add_from_file('campagne')
  Selectors.add_from_file('demarchage')
  Selectors.add_from_file('precedemment_gratuits')
  Selectors.add_from_file('nouvelles_adhesions')
  Selectors.add_from_file('reabonnements')
  Selectors.add_from_file('cadeaux')
end
