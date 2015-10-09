#!/usr/bin/env ruby
# encoding: utf-8

# File: selector.rb
# Created: 02/10/2015
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors
    Selector = Struct.new(:name, :description, :parameter_list)

    class Selector
      attr_reader :tiers_list
      # default

      def parameter_text
        'OVERRIDDEN'
      end

      def parameter_description(indx)
        "vous avez choisi le paramètre #{parameter_list[indx]}"
      end

      # @param [Array<String>] content content of a SQL source file
      # @return [String] query cleaned from comments, empty lines  and extra spaces
      def self.clean(content)
        content.lines
            .reject { |line| /^--/.match(line) }
            .map(&:chomp)
            .join(' ')
            .gsub(/\s+/, ' ')
      end

      def self.query_from_file(filename)
        content = File.read(File.join(DIRECTORY, filename))
        clean(content)
      end

    end

    class SimpleQuery < Selector
      def initialize(name, description, query, parameter_list = [])
        super(name, description, parameter_list)
        @query = Selector.clean(query)
      end

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
        # TODO; fix module
        @tiers_list = JacintheManagement::Sql.answer_to_query(JACINTHE_MODE, query).drop(1)
        @tiers_list.size
      end
    end

    class QueryFromFile < SimpleQuery
      def initialize(name, description, file_name, parameter_list = [])
        query = Selector.query_from_file(file_name)
        super(name, description, query, parameter_list)
      end
    end

    class Command < Selector
      def initialize(name, description, parameter_list = [])
        super(name, description, parameter_list)
      end

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
end

include JacintheManagement

query1 = "CALL export_cadeau_init;
SELECT tiers_id, tiers_nom
FROM tiers
  LEFT JOIN vue_tiers_adhesion_locale_premiere_annee
            ON tiers_id=nouvel_adherent
  LEFT JOIN client_sage
            ON client_sage_client_final=tiers_id
  LEFT JOIN adhesion_locale
            ON adhesion_locale_client_sage=client_sage_id
WHERE
  annee=2015
  AND adhesion_locale_annee=2015
  AND adhesion_locale_type = 'GT'"

text1 = 'Nouvelles adhésions gratuites en 2015'

sel1 = Selectors::SimpleQuery.new('GT 2015 nouveaux', text1, query1)

Selectors << sel1

query2 = "CALL export_cadeau_init;
SELECT tiers_id, adhesion_locale_type
FROM tiers
  LEFT JOIN vue_tiers_adhesion_locale_premiere_annee
            ON tiers_id=nouvel_adherent
  LEFT JOIN client_sage
            ON client_sage_client_final=tiers_id
  LEFT JOIN adhesion_locale
            ON adhesion_locale_client_sage=client_sage_id
WHERE
  annee=PARAM
  AND adhesion_locale_annee=PARAM"

text2 = "Toutes les adhésions nouvelles d'une année."

sel2 = Selectors::QueryFromFile.new('Adhésions nouvelles', text2, 'nouvelles_adhesions_gratuites.sql', %w(2014 2015))

def sel2.parameter_text
  'Choisir l\'année'
end

Selectors << sel2

sel3 = Selectors::Command.new('Commande simulée', 'Démo pour l\'ergonomie', %w(A B))

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

__END__

sel4 = Selectors::QueryFromFile.new('File', 'essai', 'nouvelles_adhesions_gratuites', %w(2014 2015))

Selectors<<sel4
