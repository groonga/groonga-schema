# Copyright (C) 2016  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

module GroongaSchema
  class Diff
    attr_reader :removed_plugins
    attr_reader :added_plugins

    attr_reader :removed_tables
    attr_reader :added_tables
    attr_reader :changed_tables

    attr_reader :removed_columns
    attr_reader :added_columns
    attr_reader :changed_columns
    def initialize
      @removed_plugins = []
      @added_plugins = []

      @removed_tables = {}
      @added_tables = {}
      @changed_tables = {}

      @removed_columns = {}
      @added_columns = {}
      @changed_columns = {}
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      @removed_plugins == other.removed_plugins and
        @added_plugins == other.added_plugins and
        @removed_tables == other.removed_tables and
        @added_tables == other.added_tables and
        @changed_tables == other.changed_tables and
        @removed_columns == other.removed_columns and
        @added_columns == other.added_columns and
        @changed_columns == other.changed_columns
    end

    def same?
      @removed_plugins.empty? and
        @added_plugins.empty? and
        @removed_tables.empty? and
        @added_tables.empty? and
        @changed_tables.empty? and
        @removed_columns.empty? and
        @added_columns.empty? and
        @changed_columns.empty?
    end

    def to_groonga_command_list(options={})
      converter = GroongaCommandListConverter.new(self, options)
      converter.convert
    end

    class GroongaCommandListConverter
      def initialize(diff, options={})
        @diff = diff
        @options = options
        @grouped_list = []
      end

      def convert
        @grouped_list.clear

        convert_added_plugins
        convert_removed_plugins

        meaningful_grouped_list = @grouped_list.reject do |group|
          group.empty?
        end
        formatted_grouped_list = meaningful_grouped_list.collect do |group|
          command_list = ""
          group.each do |command|
            command_list << "#{format_command(command)}\n"
          end
          command_list
        end
        formatted_grouped_list.join("\n")
      end

      private
      def convert_added_plugins
        sorted_plugins = @diff.added_plugins.sort_by(&:name)
        @grouped_list << sorted_plugins.collect(&:to_register_groonga_command)
      end

      def convert_removed_plugins
        sorted_plugins = @diff.removed_plugins.sort_by(&:name)
        @grouped_list << sorted_plugins.collect(&:to_unregister_groonga_command)
      end

      def format_command(command)
        case @options[:format]
        when :uri
          command.to_uri_format
        else
          command.to_command_format
        end
      end
    end
  end
end
