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
  class Table
    attr_reader :name
    attr_accessor :type
    attr_accessor :flags
    attr_accessor :key_type
    attr_accessor :value_type
    attr_accessor :default_tokenizer
    attr_accessor :normalizer
    attr_accessor :token_filters
    attr_writer :reference_key_type
    attr_accessor :columns
    def initialize(name)
      @name = name
      @type = :no_key
      @flags = []
      @key_type = nil
      @value_type = nil
      @default_tokenizer = nil
      @normalizer = nil
      @token_filters = []
      @reference_key_type = false
      @columns = []
    end

    def reference_key_type?
      @reference_key_type
    end

    def apply_command(command)
      applier = CommandApplier.new(self, command)
      applier.apply
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      @name == other.name and
        @type == other.type and
        @flags.sort == other.flags.sort and
        @key_type == other.key_type and
        @value_type == other.value_type and
        @default_tokenizer == other.default_tokenizer and
        @normalizer == other.normalizer and
        @token_filters == other.token_filters
    end

    def to_create_groonga_command
      table_create_command(@name)
    end

    def to_remove_groonga_command
      table_remove_command(@name)
    end

    def to_migrate_start_groonga_commands
      commands = []
      commands << table_create_command(new_name)
      if @columns.empty?
        commands << table_copy_command(@name, new_name)
      else
        sorted_columns = @columns.sort_by(&:name)
        sorted_columns.each do |column|
          new_column = Column.new(new_name, column.name)
          new_column.apply_column(column)
          commands << new_column.to_create_groonga_command
          commands << column.to_copy_groonga_command(new_name,
                                                     column.name)
        end
      end
      commands << table_rename_command(@name, old_name)
      commands << table_rename_command(new_name, @name)
      commands
    end

    def to_migrate_finish_groonga_commands
      [
        table_remove_command(old_name),
      ]
    end

    private
    def old_name
      "#{@name}_old"
    end

    def new_name
      "#{@name}_new"
    end

    def table_create_command(name)
      flags_value = [type_flag, *flags].join("|")
      token_filters_value = @token_filters.join("|")
      token_filters_value = nil if token_filters_value.empty?
      arguments = {
        "name"              => name,
        "flags"             => flags_value,
        "key_type"          => @key_type,
        "value_type"        => @value_type,
        "default_tokenizer" => @default_tokenizer,
        "normalizer"        => @normalizer,
        "token_filters"     => token_filters_value,
      }
      Groonga::Command::TableCreate.new(arguments)
    end

    def table_remove_command(name)
      arguments = {
        "name" => name,
      }
      Groonga::Command::TableRemove.new(arguments)
    end

    def table_copy_command(from_name, to_name)
      arguments = {
        "from_name" => from_name,
        "to_name"   => to_name,
      }
      Groonga::Command::TableCopy.new(arguments)
    end

    def table_rename_command(name, new_name)
      arguments = {
        "name"     => name,
        "new_name" => new_name,
      }
      Groonga::Command::TableRename.new(arguments)
    end

    def type_flag
      case @type
      when :no_key
        "TABLE_NO_KEY"
      when :hash_key
        "TABLE_HASH_KEY"
      when :pat_key
        "TABLE_PAT_KEY"
      when :dat_key
        "TABLE_DAT_KEY"
      else
        "TABLE_HASH_KEY"
      end
    end

    class CommandApplier
      def initialize(table, command)
        @table = table
        @command = command
      end

      def apply
        apply_flags
        apply_key_type
        apply_value_type
        apply_default_tokenizer
        apply_normalizer
        apply_token_filters
      end

      private
      def apply_flags
        @type = :no_key
        @flags = []
        @command.flags.each do |flag|
          parse_flag(flag)
        end

        @table.type = @type
        @table.flags = @flags
      end

      def parse_flag(flag)
        case flag
        when "TABLE_NO_KEY"
          @type = :no_key
        when "TABLE_HASH_KEY"
          @type = :hash_key
        when "TABLE_PAT_KEY"
          @type = :pat_key
        when "TABLE_DAT_KEY"
          @type = :dat_key
        else
          @flags << flag
        end
      end

      def apply_key_type
        case @type
        when :no_key
          @table.key_type = nil
        else
          @table.key_type = @command.key_type || "ShortText"
        end
      end

      def apply_value_type
        case @type
        when :dat_key
          @table.value_type = nil
        else
          @table.value_type = @command.value_type
        end
      end

      def apply_default_tokenizer
        case @type
        when :no_key
          @table.default_tokenizer = nil
        else
          @table.default_tokenizer = @command.default_tokenizer
        end
      end

      def apply_normalizer
        case @type
        when :no_key
          @table.normalizer = nil
        else
          @table.normalizer = @command.normalizer
        end
      end

      def apply_token_filters
        case @type
        when :no_key
          @table.token_filters = []
        else
          @table.token_filters = @command.token_filters
        end
      end
    end
  end
end
