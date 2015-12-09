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

      attr_reader :name, :description, :command_name
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
      # @return [Array<String>] Parameters to be shown in GUI
      def parameter_list
        @parameters ? @parameters.keys : nil
      end

      # @api
      # @param [String] query generic query with parameters
      # @param [Array] values transmitted by the GUI
      # @return [Array<String>] edited SQl answer
      def get_list(query, values)
        qry = parameter(query, values)
        Formatters.fetch_list(qry)
      end

      # @api
      # @return [HTML String] edited message for GUI
      # @param [Array] values transmitted by the GUI
      def creation_message(values)
        _, call, condition = extract(values)
        par = "Paramètre : #{call}." if call
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

      # @param [Array] values transmitted by the GUI
      # @return [Array] formatted parameters
      def extract(values)
        indx, condition = *values
        return [nil, nil, condition] if indx < 0
        parameter = @parameters.values[indx]
        call = @parameters.keys[indx]
        [parameter, call, condition]
      end

      # @param [String] query generic query with parameters
      # @param [Array] values transmitted by the GUI
      # @return [String] actual query
      def parameter(query, values)
        parameter, _, condition = extract(values)
        qry = parameter ? query.gsub('PARAM', parameter.to_s) : query
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
end
