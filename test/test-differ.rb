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
  def setup
    @from = GroongaSchema::Schema.new
    @to = GroongaSchema::Schema.new
    @differ = GroongaSchema::Differ.new(@from, @to)
  end

  def table_create(arguments)
    Groonga::Command::TableCreate.new(arguments)
  end

  def column_create(arguments)
    Groonga::Command::ColumnCreate.new(arguments)
  end

  sub_test_case "#diff" do
    test "table - add" do
      arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      command = table_create(arguments)
      @to.apply_command(command)

      actual = GroongaSchema::Diff.new
      actual.added_tables["Words"] = @to.tables["Words"]
      assert_equal(actual, @differ.diff)
    end

    test "table - remove" do
      arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      command = table_create(arguments)
      @from.apply_command(command)

      actual = GroongaSchema::Diff.new
      actual.removed_tables["Words"] = @from.tables["Words"]
      assert_equal(actual, @differ.diff)
    end
  end
end
