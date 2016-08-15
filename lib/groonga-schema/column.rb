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
  class Column
    attr_reader :table_name
    attr_reader :name
    attr_accessor :type
    attr_accessor :flags
    attr_accessor :value_type
    attr_accessor :sources
    attr_writer :reference_value_type
    def initialize(table_name, name)
      @table_name = table_name
      @name = name
      @type = :scalar
      @flags = []
      @value_type = "ShortText"
      @sources = []
      @reference_value_type = false
    end

    def reference_value_type?
      @reference_value_type
    end

    def apply_command(command)
      applier = CommandApplier.new(self, command)
      applier.apply
    end

    def apply_column(column)
      self.type                 = column.type
      self.flags                = column.flags
      self.value_type           = column.value_type
      self.sources              = column.sources
      self.reference_value_type = column.reference_value_type?
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      @table_name == other.table_name and
        @name == other.name and
        @type == other.type and
        @flags.sort == other.flags.sort and
        @value_type == other.value_type and
        @sources == other.sources
    end

    def to_create_groonga_command
      column_create_command(@name)
    end

    def to_remove_groonga_command
      column_remove_command(@name)
    end

    def to_copy_groonga_command(to_table_name, to_name)
      column_copy_command(to_table_name, to_name)
    end

    def to_migrate_start_groonga_commands
      commands = []
      commands << column_create_command(new_name)
      if type != :index
        commands << column_copy_command(@table_name, new_name)
      end
      commands << column_rename_command(@name, old_name)
      commands << column_rename_command(new_name, @name)
      commands
    end

    def to_migrate_finish_groonga_commands
      [
        column_remove_command(old_name),
      ]
    end

    private
    def old_name
      "#{@name}_old"
    end

    def new_name
      "#{@name}_new"
    end

    def column_create_command(name)
      flags_value = [type_flag, *flags].join("|")
      sources_value = @sources.join(",")
      sources_value = nil if sources_value.empty?
      arguments = {
        "table"  => @table_name,
        "name"   => name,
        "flags"  => flags_value,
        "type"   => @value_type,
        "source" => sources_value,
      }
      Groonga::Command::ColumnCreate.new(arguments)
    end

    def column_remove_command(name)
      arguments = {
        "table"  => @table_name,
        "name"   => name,
      }
      Groonga::Command::ColumnRemove.new(arguments)
    end

    def column_copy_command(to_table_name, to_name)
      arguments = {
        "from_table" => @table_name,
        "from_name"  => @name,
        "to_table"   => to_table_name,
        "to_name"    => to_name,
      }
      Groonga::Command::ColumnCopy.new(arguments)
    end

    def column_rename_command(name, new_name)
      arguments = {
        "table"    => @table_name,
        "name"     => name,
        "new_name" => new_name,
      }
      Groonga::Command::ColumnRename.new(arguments)
    end

    def type_flag
      case @type
      when :scalar
        "COLUMN_SCALAR"
      when :vector
        "COLUMN_VECTOR"
      when :index
        "COLUMN_INDEX"
      else
        "COLUMN_SCALAR"
      end
    end

    class CommandApplier
      def initialize(column, command)
        @column = column
        @command = command
      end

      def apply
        apply_flags
        apply_value_type
        apply_sources
      end

      private
      def apply_flags
        @type = :scalar
        @flags = []
        @command.flags.each do |flag|
          parse_flag(flag)
        end

        @column.type = @type
        @column.flags = @flags
      end

      def parse_flag(flag)
        case flag
        when "COLUMN_SCALAR"
          @type = :scalar
        when "COLUMN_VECTOR"
          @type = :vector
        when "COLUMN_INDEX"
          @type = :index
        else
          @flags << flag
        end
      end

      def apply_value_type
        # TODO: Validate for index column. Index column must have table as
        # value type.
        @column.value_type = @command.type
      end

      def apply_sources
        case @type
        when :index
          @column.sources = @command.sources
        else
          @column.sources = []
        end
      end
    end
  end
end
