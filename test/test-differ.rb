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

class DifferTest < Test::Unit::TestCase
  setup do
    @from = GroongaSchema::Schema.new
    @to = GroongaSchema::Schema.new
    @differ = GroongaSchema::Differ.new(@from, @to)
  end

  def plugin_register(arguments)
    Groonga::Command::PluginRegister.new(arguments)
  end

  def table_create(arguments)
    Groonga::Command::TableCreate.new(arguments)
  end

  def column_create(arguments)
    Groonga::Command::ColumnCreate.new(arguments)
  end

  sub_test_case "#diff" do
    test "plugin - add" do
      @to.apply_command(plugin_register("name" => "token_filters/stem"))

      expected = GroongaSchema::Diff.new
      expected.added_plugins.concat(@to.plugins)
      assert_equal(expected, @differ.diff)
    end

    test "plugin - remove" do
      @from.apply_command(plugin_register("name" => "token_filters/stem"))

      expected = GroongaSchema::Diff.new
      expected.removed_plugins.concat(@from.plugins)
      assert_equal(expected, @differ.diff)
    end

    test "table - add - without columns" do
      arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      @to.apply_command(table_create(arguments))

      expected = GroongaSchema::Diff.new
      expected.added_tables["Words"] = @to.tables["Words"]
      assert_equal(expected, @differ.diff)
    end

    test "table - add - with columns" do
      table_create_arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      @to.apply_command(table_create(table_create_arguments))
      column_create_arguments = {
        "table"  => "Words",
        "name"   => "entries_text",
        "flags"  => "COLUMN_INDEX|WITH_POSITION|WITH_SECTION|INDEX_TINY",
        "type"   => "Entries",
        "source" => "title, content",
      }
      @to.apply_command(column_create(column_create_arguments))

      expected = GroongaSchema::Diff.new
      expected.added_tables["Words"] = @to.tables["Words"]
      expected.added_columns["Words"] = {
        "entries_text" => @to.columns["Words"]["entries_text"],
      }
      assert_equal(expected, @differ.diff)
    end

    test "table - remove - without columns" do
      arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      @from.apply_command(table_create(arguments))

      expected = GroongaSchema::Diff.new
      expected.removed_tables["Words"] = @from.tables["Words"]
      assert_equal(expected, @differ.diff)
    end

    test "table - remove - with columns" do
      table_create_arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      @from.apply_command(table_create(table_create_arguments))
      column_create_arguments = {
        "table"  => "Words",
        "name"   => "entries_text",
        "flags"  => "COLUMN_INDEX|WITH_POSITION|WITH_SECTION|INDEX_TINY",
        "type"   => "Entries",
        "source" => "title, content",
      }
      @from.apply_command(column_create(column_create_arguments))

      expected = GroongaSchema::Diff.new
      expected.removed_tables["Words"] = @from.tables["Words"]
      assert_equal(expected, @differ.diff)
    end

    test "table - change" do
      from_arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      to_arguments = from_arguments.merge("default_tokenizer" => "TokenMecab")
      @from.apply_command(table_create(from_arguments))
      @to.apply_command(table_create(to_arguments))

      expected = GroongaSchema::Diff.new
      expected.changed_tables["Words"] = @to.tables["Words"]
      assert_equal(expected, @differ.diff)
    end

    sub_test_case "column" do
      setup do
        arguments = {
          "name"              => "Words",
          "flags"             => "TABLE_PAT_KEY",
          "key_type"          => "ShortText",
          "default_tokenizer" => "TokenBigram",
          "normalizer"        => "NormalizerAuto",
          "token_filters"     => "TokenStem|TokenStopWord",
        }
        @from.apply_command(table_create(arguments))
        @to.apply_command(table_create(arguments))
      end

    test "add" do
      arguments = {
        "table"  => "Words",
        "name"   => "entries_text",
        "flags"  => "COLUMN_INDEX|WITH_POSITION|WITH_SECTION|INDEX_TINY",
        "type"   => "Entries",
        "source" => "title, content",
      }
      @to.apply_command(column_create(arguments))

      expected = GroongaSchema::Diff.new
      expected.added_columns["Words"] = {
        "entries_text" => @to.columns["Words"]["entries_text"],
      }
      assert_equal(expected, @differ.diff)
    end

    test "remove" do
      arguments = {
        "table"  => "Words",
        "name"   => "entries_text",
        "flags"  => "COLUMN_INDEX|WITH_POSITION|WITH_SECTION|INDEX_TINY",
        "type"   => "Entries",
        "source" => "title, content",
      }
      @from.apply_command(column_create(arguments))

      expected = GroongaSchema::Diff.new
      expected.removed_columns["Words"] = {
        "entries_text" => @from.columns["Words"]["entries_text"],
      }
      assert_equal(expected, @differ.diff)
    end

    test "change" do
      from_arguments = {
        "table"  => "Words",
        "name"   => "entries_text",
        "flags"  => "COLUMN_INDEX|WITH_POSITION|WITH_SECTION|INDEX_TINY",
        "type"   => "Entries",
        "source" => "title, content",
      }
      to_arguments = from_arguments.merge("source" => "title")
      @from.apply_command(column_create(from_arguments))
      @to.apply_command(column_create(to_arguments))

      expected = GroongaSchema::Diff.new
      expected.changed_columns["Words"] = {
        "entries_text" => @to.columns["Words"]["entries_text"],
      }
      assert_equal(expected, @differ.diff)
    end
    end
  end
end
