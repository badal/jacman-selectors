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
      attr_reader :name, :description, :parameter_list, :command_name, :tiers_list

      def initialize(hsh)
        hsh.each_pair do |key, value|
          # self.attr_accessor key.to_sym
          instance_variable_set("@#{key}", value)
          # define_method key.to_sym { instance_variable_get :"@#{key}"}
        end
      end

      def year_choice
        case @years
        when 'complex'
          ['= 2015', '= 2014', '<= 2013']
        when 'simple'
          ['= 2015', '= 2014']
        end
      end

      def self.from_file(path)
        hsh = YAML.load_file(path)
        new(hsh)
      end

      def command_message
        ['Vous pouvez tout aussi bien :<ul>',
         '<li>router</li>',
         "<li>lancer la commande par le bouton '#{command_name}'</li>",
         '<li> lancer la commande, puis router</li>',
         '<li>router, puis lancer la commande</li></ul><hr>'].join
      end

      def parameter_value(indx)
        @parameter_list[indx]
      end

      def extract(values)
        indx, condition = *values
        parameter = "'#{@parameter_list[indx]}'" if (indx >= 0)
        [parameter, condition]
      end

      def parameter(query, values)
        parameter, condition = extract(values)
        qry = parameter ? query.gsub('PARAM', parameter) : query
        condition ? qry.gsub('CONDITION', condition) : qry
      end

      def get_list(query, values)
        qry = parameter(query, values)
        Sql.answer_to_query(JACINTHE_MODE, qry).drop(1)
      end

      def creation_message(values)
        parameter, condition = extract(values)
        par = "Paramètre : #{parameter}." if parameter
        ann = "Année de référence #{condition.sub('<=', '&le;')}." if @years
        text = 'Vous pouvez créer la sélection.'
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
