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
      attr_reader :name, :description, :parameter_list

      def initialize(hsh)
        hsh.each_pair do |key, value|
          # self.attr_accessor key.to_sym
          self.instance_variable_set("@#{key}", value)
          # define_method key.to_sym { instance_variable_get :"@#{key}"}
        end
      end

      def self.from_file(filename)
        hsh = YAML.load_file(File.join(DIRECTORY, filename))
        new(hsh)
      end

      def parameter_description(indx)
        "vous avez choisi le paramètre #{parameter_list[indx]}"
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
    end

    class SimpleQuery < Selector
      def command_name
        nil
      end

      def query_for(indx)
        if indx < 0
          @query
        else
         @query.gsub('PARAM', parameter_list[indx])
        end
      end

      def build_tiers_list(indx)
        query = query_for(indx)
        @tiers_list = Sql.answer_to_query(JACINTHE_MODE, query).drop(1)
        @tiers_list.size
      end
    end

    class Command < Selector

      def command_name
        'Nom spécifique'
      end

      def command_message
        ['Vous pouvez aussi bien<ul><li>router</li>',
         "<li>lancer la commande par le bouton '#{command_name}'</li>",
         '<li> lancer la commande, puis router</li>',
         '<li>router, puis lancer la commande</li></ul><hr>'].join
      end

      def build_tiers_list(_indx)
        'OVERRIDDEN'
        0
      end

      def execute
        'OVERRIDDEN'
      end
    end
  end

  Selectors << Selectors::SimpleQuery.from_file('precedemment_gratuits')

  Selectors << Selectors::SimpleQuery.from_file('nouvelles_adhesions_gratuites')

  sel3 = Selectors::Command.new(name: 'Commande simulée',
                                description: 'Démo pour l\'ergonomie', parameter_list: %w(A B))

  def sel3.build_tiers_list(_indx)
    @tiers_list = [14, 15, 16, 17, 383]
    @tiers_list.size
  end

  def sel3.command_name
    'Marquer les cadeaux'
  end

  def sel3.execute
    'Cadeaux marqués'
  end

  Selectors << sel3
  p Selectors.all
end

