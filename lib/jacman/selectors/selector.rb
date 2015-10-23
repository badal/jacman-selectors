#!/usr/bin/env ruby
# encoding: utf-8

# File: selector.rb
# Created: 02/10/2015
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors
    # selectors for the Selector GUI
    class Selector
      # SQL fragment for Tiers description
      TIERS_DESCRIPTION = "tiers_id, CONCAT_WS(' ', tiers_prenom, tiers_nom), tiers_adresse_ville, tiers_adresse_pays"
      # Labels for the above fragment
      FIRST_LABELS = %w(tiers_id Nom Ville Pays)

      # partial pattern
      NO_TAB_TAB = '[^\\t]*\\t'
      # pattern to separate the country id
      PATTERN = Regexp.new('(^' + NO_TAB_TAB * 3 + ')(\d*)(\\t.*)$')

      # SQL generic tool to extract the array : id -> name from basic tables
      #
      # @param [String] table SQL table
      # @return [Array<String>] array array of names
      def self.extract_from(table)
        list = Sql.answer_to_query(JACINTHE_MODE, "select * from #{table}").drop(1)
        res = []
        list.each do |line|
          id, name = *line.chomp.split("\t")
          res[id.to_i] = name
        end
        res
      end

      # @return [Array<String>] name of countries, accessed by 'pays_id'
      def self.countries
        @countries ||= extract_from('pays')
      end

      # Replace in SQL answer the country id by the country name
      #
      # @param [String] line line from SQL answer
      # @return [String] completed line
      def self.fix_line(line)
        if PATTERN.match(line)
          Regexp.last_match(1) + countries[Regexp.last_match(2).to_i] + Regexp.last_match(3)
        else
          line
        end
      end

      @year = Time.now.year
      @month = Time.now.month

      # @return [Range] back years to put in menu
      def self.range_for_month
        case @month
        when 1..3
          (0..2)
        when 4..9
          (0..1)
        when 10..12
          (-1..1)
        end
      end

      # @param [Boolean] complex type of menu
      # @return [Array<String>] menu items
      def self.year_choice(complex)
        range = range_for_month
        simple = range.each.map do |val|
          "= #{@year - val}"
        end
        complex ? simple << "<= #{@year - range.end - 1}" : simple
      end

      # @param [Path] path path of file to read selector from
      # @return [Selector] selector read from the given file
      def self.from_file(path)
        new(YAML.load_file(path))
      end

      # only external API values
      attr_reader :name, :description, :parameter_list, :command_name
      attr_accessor :tiers_list

      # @param [Hash] hsh Hash of instance initial values
      # @return [Selector] a new instance
      def initialize(hsh)
        hsh.each_pair do |key, value|
          # self.attr_accessor key.to_sym
          instance_variable_set("@#{key}", value)
          # define_method key.to_sym { instance_variable_get :"@#{key}"}
        end
      end

      # @api
      # @param [String] query generic query with parameters
      # @param [Array] values transmitted by the GUI
      # @return [Array<String>] edited SQl answer
      def get_list(query, values)
        qry = parameter(query, values)
        list = Sql.answer_to_query(JACINTHE_MODE, qry)
        list.map { |line| Selector.fix_line(line) }
      end

      # @api
      # @return [HTML String] edited message for GUI
      # @param [Array] values transmitted by the GUI
      def creation_message(values)
        parameter, condition = extract(values)
        par = "Paramètre : #{parameter}." if parameter
        ann = "Année de référence #{condition.sub('<=', '&le;')}." if @years
        text = 'Vous pouvez créer la sélection.'
        [par, ann, text].compact.join('<br>')
      end

      # @api
      # @return [HTML String] message (when selector includes a command)
      def command_message
        ['Vous pouvez tout aussi bien :<ul>',
         '<li>router</li>',
         "<li>lancer la commande par le bouton '#{command_name}'</li>",
         '<li> lancer la commande, puis router</li>',
         '<li>router, puis lancer la commande</li></ul><hr>'].join
      end

      # @api
      # Build the tiers_list
      #
      # @param [Array] values transmitted by the GUI
      # @return [Fixnum] number of content lines (excluding field names line)
      def build_tiers_list(values)
        @tiers_list = get_list(@query, values)
        @tiers_list.size - 1
      end

      # @api
      # @param [Array] values transmitted by the GUI
      # @return [String] report
      def execute(values)
        cmds = command(values)
        Sql.query(JACINTHE_MODE, cmds.join(';'))
        'Commande exécutée'
      end

      # private from here

      # @return [Array<String>] menu for the @years choice
      def year_choice
        case @years
        when 'complex'
          Selector.year_choice(true)
        when 'simple'
          Selector.year_choice(false)
        end
      end

      # @param [Fixnum] indx index
      # @return [String] parameter value for this index
      def parameter_value(indx)
        @parameter_list[indx]
      end

      # @param [Array] values transmitted by the GUI
      # @return [Array] formatted parameters
      def extract(values)
        indx, condition = *values
        parameter = "'#{@parameter_list[indx]}'" if (indx >= 0)
        [parameter, condition]
      end

      # @param [String] query generic query with parameters
      # @param [Array] values transmitted by the GUI
      # @return [String] actual query
      def parameter(query, values)
        query.sub!('TIERS_DESC', TIERS_DESCRIPTION)
        parameter, condition = extract(values)
        qry = parameter ? query.gsub('PARAM', parameter) : query
        condition ? qry.gsub('CONDITION', condition) : qry
      end

      # @param [Array] values transmitted by the GUI
      # @return [String] actual query of command
      def command(values)
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
