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
        convert_added_tables
        convert_removed_columns
        convert_removed_tables
        convert_removed_plugins
        convert_changed_tables

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

      def convert_added_tables
        sorted_tables = @diff.added_tables.sort_by do |name, table|
          [
            table.reference_key_type? ? 1 : 0,
            table.name,
          ]
        end

        sorted_tables.each do |name, table|
          group = []
          group << table.to_create_groonga_command
          group.concat(convert_added_columns(name, false))
          @grouped_list << group
        end

        sorted_tables.each do |name, table|
          @grouped_list << convert_added_columns(name, true)
        end
      end

      def convert_added_columns(name, target_is_reference_type)
        columns = @diff.added_columns[name]
        return [] if columns.nil?

        sorted_columns = columns.sort_by do |column_name,|
          column_name
        end

        group = []
        sorted_columns.each do |column_name, column|
          if target_is_reference_type
            next unless column.reference_value_type?
          else
            next if column.reference_value_type?
          end
          group << column.to_create_groonga_command
        end
        group
      end

      def convert_removed_columns
        sorted_removed_columns = @diff.removed_columns.sort_by do |table_name,|
          table_name
        end

        column_groups = []
        sorted_removed_columns.each do |table_name, columns|
          group = []
          columns.each do |column_name, column|
            group << column unless column.sources.empty?
          end
          next if group.empty?
          column_groups << group
        end
        sorted_removed_columns.each do |table_name, columns|
          group = []
          columns.each do |column_name, column|
            group << column if column.sources.empty?
          end
          next if group.empty?
          column_groups << group
        end

        column_groups.each do |columns|
          sorted_columns = columns.sort_by do |column|
            column.name
          end
          group = sorted_columns.collect do |column|
            column.to_remove_groonga_command
          end
          @grouped_list << group
        end
      end

      def convert_removed_tables
        sorted_tables = @diff.removed_tables.sort_by do |name, table|
          [
            table.reference_key_type? ? 0 : 1,
            table.name,
          ]
        end

        sorted_tables.each do |name, table|
          @grouped_list << [table.to_remove_groonga_command]
        end
      end

      def convert_removed_plugins
        sorted_plugins = @diff.removed_plugins.sort_by(&:name)
        @grouped_list << sorted_plugins.collect(&:to_unregister_groonga_command)
      end

      def convert_changed_tables
        sorted_tables = @diff.changed_tables.sort_by do |name, table|
          [
            table.reference_key_type? ? 1 : 0,
            table.name,
          ]
        end

        sorted_tables.each do |name, table|
          @grouped_list << table.to_migrate_start_groonga_commands
        end
        convert_changed_columns
        sorted_tables.each do |name, table|
          @grouped_list << table.to_migrate_finish_groonga_commands
        end
      end

      def convert_changed_columns
        all_columns = []
        @diff.changed_columns.each do |table_name, columns|
          all_columns.concat(columns.values)
        end

        sorted_columns = all_columns.sort_by do |column|
          [
            (column.type == :index) ? 1 : 0,
            column.table_name,
            column.name,
          ]
        end
        sorted_columns.each do |column|
          @grouped_list << column.to_migrate_start_groonga_commands
        end

        sorted_columns = all_columns.sort_by do |column|
          [
            (column.type == :index) ? 0 : 1,
            column.table_name,
            column.name,
          ]
        end
        sorted_columns.each do |column|
          @grouped_list << column.to_migrate_finish_groonga_commands
        end
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
