#!/usr/bin/env ruby
# encoding: utf-8

# File: formatters.rb
# Created: 26/11/15 extracted from selector.rb
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors
    # formatters for queries and results
    module Formatters
      @formatters = []

      # assigns relevant formatters
      # @param [String] query to be formatted
      def self.assign_formatters(query)
        @formatters << Formatter.new
        @formatters << FormatterTiersDesc.new if query['TIERS_DESC']
        @formatters << FormatterTiersAdr.new if query['TIERS_ADR']
      end

      # applies all formatters
      # @param [String] query to be formatted
      # @return [String] formatted query
      def self.explicit(query)
        @formatters.reduce(query) do |acc, formatter|
          formatter.explicit(acc)
        end
      end

      # apply all formatters
      # @param [Array<String>] list MySql raw answer
      # @return [Array<String>] answer formatted for user
      def self.fix_format(list)
        return list if list.empty?
        @formatters.reduce(list) do |acc, formatter|
          formatter.fix_format(acc)
        end
      end

      # apply all formatters
      # @param [String] query to be formatted and sent to MySql
      # @return [Array<String>] formatted table content
      def self.fetch_list(query)
        assign_formatters(query)
        qry = explicit(query)
        list = Sql.answer_to_query(JACINTHE_MODE, qry)
        fix_format(list)
      end
    end

    # generic class
    class Formatter
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

      # identity
      # @param [String] query to be formatted
      # @return [String] formatted query
      def explicit(query)
        query
      end

      # identity
      # @param [String] old_labels fields separated by tabs
      # @return [String] formatted labels separated by tabs
      def fix_labels(old_labels)
        old_labels
      end

      # identity
      # @param [String] line  MySql answer line
      # @return [String] formatted line for table
      def fix_line(line)
        line
      end

      # generic
      # @param [Array<String>] list MySql raw answer
      # @return [Array<String>] answer formatted for table
      def fix_format(list)
        labels = fix_labels(list.shift)
        [labels] + list.map { |line| fix_line(line) }
      end
    end

    # formatter for nice tiers description
    class FormatterTiersDesc < Formatter
      # SQL fragment for Tiers description
      TIERS_DESCRIPTION = "tiers_id, CONCAT_WS(' ', tiers_prenom, tiers_nom),\
 tiers_adresse_ville, tiers_adresse_pays"

      # Labels for the above fragment
      FIRST_LABELS = %w(tiers_id Nom Ville Pays)

      # partial pattern
      NO_TAB_TAB = '[^\\t]*\\t'

      # pattern to fix labels
      LABELS_PATTERN = '(^' + NO_TAB_TAB * 4 + ')'

      # pattern to separate the country id
      PATTERN = Regexp.new('(^' + NO_TAB_TAB * 3 + ')(\d*)(\\t.*)$')

      # Replace in SQL answer the country id by the country name
      #
      # @param [String] line line from SQL answer
      # @return [String] completed line
      def fix_line(line)
        if PATTERN.match(line)
          Regexp.last_match(1) +
            Formatter.countries[Regexp.last_match(2).to_i] +
            Regexp.last_match(3)
        else
          line
        end
      end

      # @param [String] old_labels fields separated by tabs
      # @return [String] formatted labels separated by tabs
      def fix_labels(old_labels)
        old_labels.sub(Regexp.new(LABELS_PATTERN), FIRST_LABELS.join("\t") + "\t")
      end

      # @param [String] query to be formatted
      # @return [String] formatted query
      def explicit(query)
        query.sub('TIERS_DESC', TIERS_DESCRIPTION)
      end
    end

    # Formatter for full address
    class FormatterTiersAdr < Formatter
      # query for address
      ADDRESS_CALL = 'get_tiers_adresse_for_usage(tiers_id, 1)'

      # @param [String] old_labels fields separated by tabs
      # @return [String] formatted labels separated by tabs
      def fix_labels(old_labels)
        old_labels.sub(ADDRESS_CALL, 'Adresse')
      end

      # @param [String] query to be formatted
      # @return [String] formatted query
      def explicit(query)
        query.sub('TIERS_ADR', ADDRESS_CALL)
      end
    end
  end
end
