#!/usr/bin/env ruby
# encoding: utf-8

# File: selector.rb
# Created: 02/10/2015
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors
    class Selector
      TIERS_DESCRIPTION = "tiers_id, CONCAT_WS(' ', tiers_prenom, tiers_nom), tiers_adresse_ville, tiers_adresse_pays"
      FIRST_LABELS = %w(tiers_id Nom Ville Pays)

      NO_TAB_TAB = '[^\\t]*\\t'
      PATTERN = Regexp.new('(^' + NO_TAB_TAB * 3 + ')(\d*)(\\t.*)$')

      def self.extract_from(table)
        list = Sql.answer_to_query(JACINTHE_MODE, "select * from #{table}").drop(1)
        res = []
        list.each do |line|
          id, name = *line.chomp.split("\t")
          res[id.to_i] = name
        end
        res
      end

      def self.countries
        @countries ||= extract_from('pays')
      end

      def self.fix_line(line)
        if PATTERN.match(line) then
          Regexp.last_match(1) + countries[Regexp.last_match(2).to_i] + Regexp.last_match(3)
        else
          line
        end
      end

      # only external API values
      attr_reader :name, :description, :parameter_list, :command_name
      attr_accessor :tiers_list

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
        query.sub!('TIERS_DESC', TIERS_DESCRIPTION)
        parameter, condition = extract(values)
        qry = parameter ? query.gsub('PARAM', parameter) : query
        condition ? qry.gsub('CONDITION', condition) : qry
      end

      def get_list(query, values)
        qry = parameter(query, values)
        list = Sql.answer_to_query(JACINTHE_MODE, qry)
        list.map { |line| Selector.fix_line(line) }
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
        @tiers_list.size - 1
      end

      def execute(values)
        cmds = commands(values)
        Sql.query(JACINTHE_MODE, cmds.join(';'))
        'Commande exécutée'
      end

      def commands(values)
        qry = parameter(@command_query, values)
        @tiers_list.drop(1).map do |line|
          tiers_id = line.split("\t").first
          qry.sub('TIERS_ID', tiers_id)
        end
      end
    end
  end

  # p Selectors.all
end
