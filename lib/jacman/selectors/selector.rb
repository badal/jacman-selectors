#!/usr/bin/env ruby
# encoding: utf-8

# File: selector.rb
# Created: 02/10/2015
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors
    class Selector
      # only external API values
      attr_reader :name, :description, :years, :tiers_list, :command_name

      def initialize(hsh)
        hsh.each_pair do |key, value|
          # self.attr_accessor key.to_sym
          instance_variable_set("@#{key}", value)
          # define_method key.to_sym { instance_variable_get :"@#{key}"}
        end
      end

      def self.from_file(filename)
        hsh = YAML.load_file(File.join(DIRECTORY, filename))
        new(hsh)
      end

      def command_message
        ['Vous pouvez tout aussi bien :<ul>',
         '<li>router</li>',
         "<li>lancer la commande par le bouton '#{command_name}'</li>",
         '<li> lancer la commande, puis router</li>',
         '<li>router, puis lancer la commande</li></ul><hr>'].join
      end
    end

    class SimpleQuery < Selector

      attr_reader :parameter_list

      def parameter_value(indx)
        @parameter_list[indx]
      end

      def parameter(query, values)
        indx, year = *values
        qry = (indx < 0) ? query : query.gsub('PARAM', "'#{parameter_value(indx)}'")
        @years ? qry.gsub(/YEAR/, year.to_s) : qry
      end

      def get_list(query, values)
        qry = parameter(query, values)
        Sql.answer_to_query(JACINTHE_MODE, qry).drop(1)
      end

      def creation_message(values)
        indx, year = *values
        par = "Paramètre : #{parameter_value(indx)}" if indx >= 0
        ann = "Année de référence : #{@years[year]}" if @years
        text = 'Vous pouvez créer la sélection'
        [par, ann, text].compact.join('<br>')
      end

      def build_tiers_list(values)
        @tiers_list = get_list(@query, values)
        @tiers_list.size
      end

      def execute(values)
        qry = parameter(@execute_query, values)
      end
    end
  end

  Selectors.add_from_file('pour_essai')
  Selectors.add_from_file('campagne')
  Selectors.add_from_file('demarchage')
  Selectors.add_from_file('precedemment_gratuits')
  Selectors.add_from_file('nouvelles_adhesions')
  Selectors.add_from_file('reabonnements')
  Selectors.add_from_file('cadeaux')

  # p Selectors.all
end

# TODO : useless with YAML, just kept in case
# # @param [Array<String>] content content of a SQL source file
# # @return [String] query cleaned from comments, empty lines  and extra spaces
# def self.clean(content)
#   content.lines
#       .reject { |line| /^--/.match(line) }
#       .map(&:chomp)
#       .join(' ')
#       .gsub(/\s+/, ' ')
# end
#
# def self.query_from_file(filename)
#   content = File.read(File.join(DIRECTORY, filename))
#   clean(content)
# end
