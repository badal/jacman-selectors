#!/usr/bin/env ruby
# encoding: utf-8

# File: table.rb
# Created: 11/12/2015
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors
    # specific class for Qt widget
    class Table
      # @param [Array<String>] list answer from MySQL
      # @return [Table] new instance
      def self.from_sql(list)
        contents = list.map do |line|
          line.chomp.split("\t")
        end
        labels = contents.shift
        new(labels, contents)
      end

      attr_reader :labels, :rows
      # @param [Array<String>] labels label row
      # @param [Array<Array<String>>] rows list of rows
      def initialize(labels = [], rows = [[]])
        @labels = labels
        @rows = rows
      end

      # @return [Integer] number of rows
      def row_count
        @rows.size
      end

      # @return [Integer] number of columns
      def column_count
        @labels.size
      end

      # @return [Array] list of tiers_id for routing
      def tiers_list
        return [] unless @labels.first == 'tiers_id'
        @rows.map(&:first)
      end

      # @param [String] csv_separator separator for csv files
      # @return [String] formatted output
      def output_content(csv_separator)
        ([@labels] + @rows).map do |line|
          line.join(csv_separator)
        end.join("\n")
      end

      # @param [Array<Array<String>>] rows new set of rows
      # @return [Table] new Table with same labels and given rows
      def fix_rows(rows)
        self.class.new(@labels, rows)
      end
    end
  end
end
