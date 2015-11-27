#!/usr/bin/env ruby
# encoding: utf-8

# File: formatters.rb
# Created: 26/11/15 extracted from selector.rb
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors
    module Formatters
      @formatters = []

      def self.assign_formatters(query)
        @formatters << Formatter.new
        @formatters << FormatterTiersDesc.new if query['TIERS_DESC']
        @formatters << FormatterTiersAdr.new if query['TIERS_ADR']
      end

      def self.explicit(query)
        assign_formatters(query)

        @formatters.reduce(query) do |acc, formatter|
          formatter.explicit(acc)
        end
      end

      def self.fix_format(list)
        @formatters.reduce(list) do |acc, formatter|
          formatter.fix_format(acc)
        end
      end
    end

    class Formatter
      def explicit(query)
        query
      end

      def fix_labels(old_labels)
        old_labels
      end

      def fix_line(line)
        line
      end

      def fix_format(list)
        labels = fix_labels(list.shift)
        [labels] + list.map { |line| fix_line(line) }
      end
    end

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

      # SQL generic tool to extract the array : id -> name from basic tables
      #
      # @param [String] table SQL table
      # @return [Array<String>] array array of names
      def extract_from(table)
        list = Sql.answer_to_query(JACINTHE_MODE, "select * from #{table}").drop(1)
        res = []
        list.each do |line|
          id, name = *line.chomp.split("\t")
          res[id.to_i] = name
        end
        res
      end

      # @return [Array<String>] name of countries, accessed by 'pays_id'
      def countries
        @countries ||= extract_from('pays')
      end

      # Replace in SQL answer the country id by the country name
      #
      # @param [String] line line from SQL answer
      # @return [String] completed line
      def fix_line(line)
        if PATTERN.match(line)
          Regexp.last_match(1) + countries[Regexp.last_match(2).to_i] + Regexp.last_match(3)
        else
          line
        end
      end

      def fix_labels(old_labels)
        old_labels.sub(Regexp.new(LABELS_PATTERN), FIRST_LABELS.join("\t") + "\t")
      end

      def explicit(query)
        query.sub('TIERS_DESC', TIERS_DESCRIPTION)
      end
    end

    class FormatterTiersAdr < Formatter
      def fix_labels(old_labels)
        "#{old_labels}\tAdresse"
      end

      def explicit(query)
        query.sub('+TIERS_ADR', '')
      end

      def fix_line(line)
        "#{line}\tadresse"
      end
    end
  end
end
