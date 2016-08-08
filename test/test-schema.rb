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

class SchemaTest < Test::Unit::TestCase
  def setup
    @schema = GroongaSchema::Schema.new
  end

  def table_create(arguments)
    Groonga::Command::TableCreate.new(arguments)
  end

  def column_create(arguments)
    Groonga::Command::ColumnCreate.new(arguments)
  end

  sub_test_case "#apply_command" do
    test "lexicon" do
      arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      command = table_create(arguments)
      @schema.apply_command(command)

      table_data = @schema.tables.collect do |name, table|
        {
          :name              => name,
          :type              => table.type,
          :flags             => table.flags,
          :key_type          => table.key_type,
          :value_type        => table.value_type,
          :default_tokenizer => table.default_tokenizer,
          :normalizer        => table.normalizer,
          :token_filters     => table.token_filters,
        }
      end
      assert_equal([
                     {
                       :name              => "Words",
                       :type              => :pat_key,
                       :flags             => [],
                       :key_type          => "ShortText",
                       :value_type        => nil,
                       :default_tokenizer => "TokenBigram",
                       :normalizer        => "NormalizerAuto",
                       :token_filters     => ["TokenStem", "TokenStopWord"],
                     },
                   ],
                   table_data)
    end

    test "index column" do
      arguments = {
        "table"  => "Words",
        "name"   => "entries_text",
        "flags"  => "COLUMN_INDEX|WITH_POSITION|WITH_SECTION|INDEX_TINY",
        "type"   => "Entries",
        "source" => "title, content",
      }
      command = column_create(arguments)
      @schema.apply_command(command)

      column_data = []
      @schema.columns.each do |table_name, columns|
        columns.each do |column_name, column|
          column_data << {
            :table_name => table_name,
            :name       => column_name,
            :type       => column.type,
            :flags      => column.flags,
            :value_type => column.value_type,
            :sources    => column.sources,
          }
        end
      end
      assert_equal([
                     {
                       :table_name => "Words",
                       :name       => "entries_text",
                       :type       => :index,
                       :flags      => ["WITH_POSITION", "WITH_SECTION", "INDEX_TINY"],
                       :value_type => "Entries",
                       :sources    => ["title", "content"],
                     },
                   ],
                   column_data)
    end
  end
end
