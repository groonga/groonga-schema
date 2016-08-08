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

    def to_groonga_command_list
      converter = GroongaCommandListConverter.new(self)
      converter.convert
    end

    class GroongaCommandListConverter
      def initialize(diff)
        @diff = diff
        @buffer = ""
      end

      def convert
        @buffer.clear
        convert_added_plugins
        convert_removed_plugins
        @buffer
      end

      private
      def convert_added_plugins
        return if @diff.added_plugins.empty?

        @buffer << "\n" unless @buffer.empty?
        @diff.added_plugins.sort_by(&:name).each do |plugin|
          @buffer << "plugin_register #{plugin.name}\n"
        end
      end

      def convert_removed_plugins
        return if @diff.removed_plugins.empty?

        @buffer << "\n" unless @buffer.empty?
        @diff.removed_plugins.sort_by(&:name).each do |plugin|
          @buffer << "plugin_unregister #{plugin.name}\n"
        end
      end
    end
  end
end
