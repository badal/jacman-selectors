#!/usr/bin/env ruby
# encoding: utf-8

# File: table.rb
# Created: 11/12/2015
#
# (c) Michel Demazure <michel@demazure.com>

module JacintheManagement
  module Selectors


    class Table

      def self.from_sql(list)
        contents = list.map do |line|
          line.chomp.split("\t")
        end
        labels = contents.shift
        new(labels, contents)
      end

      attr_reader :labels, :rows

      def initialize(labels = [], rows = [[]])
        @labels = labels
        @rows = rows
      end

      def row_count
        @rows.size
      end

      def column_count
        @labels.size
      end

      def tiers_list
        return [] unless @labels.first == 'tiers_id'
        @rows.map(&:first)
      end

      def output_content(csv_separator)
         ([@labels] + @rows).map do |line|
            line.join(csv_separator)
          end.join("\n")
      end

      def fix_rows(rows)
        self.class.new(@labels, rows)
      end

    end
  end
end
