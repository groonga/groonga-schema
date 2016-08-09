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

class DiffTest < Test::Unit::TestCase
  def setup
    @diff = GroongaSchema::Diff.new
  end

  def plugin(name)
    GroongaSchema::Plugin.new(name)
  end

  def table(name, options)
    table = GroongaSchema::Table.new(name)
    options.each do |key, value|
      table.__send__("#{key}=", value)
    end
    table
  end

  def column(table_name, name, options)
    column = GroongaSchema::Column.new(table_name, name)
    options.each do |key, value|
      column.__send__("#{key}=", value)
    end
    column
  end

  sub_test_case "#same?" do
    test "same" do
      assert do
        @diff.same?
      end
    end

    test "different" do
      @diff.added_plugins << plugin("token_filters/stem")
      assert do
        not @diff.same?
      end
    end
  end

  sub_test_case "#to_groonga_command_list" do
    test "plugins" do
      @diff.added_plugins << plugin("token_filters/stem")
      @diff.removed_plugins << plugin("token_filters/stop_word")
      assert_equal(<<-LIST, @diff.to_groonga_command_list)
plugin_register --name "token_filters/stem"

plugin_unregister --name "token_filters/stop_word"
      LIST
    end

    test "added tables - without column" do
      token_filters = [
        "TokenFilterStopWord",
        "TokenFilterStem",
      ]
      @diff.added_tables["Words"] = table("Words",
                                          :type => :pat_key,
                                          :key_type => "ShortText",
                                          :default_tokenizer => "TokenBigram",
                                          :normalizer => "NormalizerAuto",
                                          :token_filters => token_filters)
      @diff.added_tables["Names"] = table("Names",
                                          :type => :hash_key,
                                          :flags => "KEY_LARGE",
                                          :key_type => "ShortText",
                                          :normalizer => "NormalizerAuto")
      @diff.added_tables["Commands"] = table("Commands",
                                             :type => :hash_key,
                                             :key_type => "Names",
                                             :reference_key_type => true)

      assert_equal(<<-LIST.gsub(/\\\n\s+/, ""), @diff.to_groonga_command_list)
table_create \\
  --flags "TABLE_HASH_KEY|KEY_LARGE" \\
  --key_type "ShortText" \\
  --name "Names" \\
  --normalizer "NormalizerAuto"

table_create \\
  --default_tokenizer "TokenBigram" \\
  --flags "TABLE_PAT_KEY" \\
  --key_type "ShortText" \\
  --name "Words" \\
  --normalizer "NormalizerAuto" \\
  --token_filters "TokenFilterStopWord|TokenFilterStem"

table_create \\
  --flags "TABLE_HASH_KEY" \\
  --key_type "Names" \\
  --name "Commands"
      LIST
    end

    test "added tables - with column" do
      @diff.added_tables["Names"] = table("Names",
                                          :type => :hash_key,
                                          :flags => "KEY_LARGE",
                                          :key_type => "ShortText",
                                          :normalizer => "NormalizerAuto")
      @diff.added_tables["Commands"] = table("Commands",
                                             :type => :hash_key,
                                             :key_type => "Names",
                                             :reference_key_type => true)
      @diff.added_columns["Commands"] = {
        "description" => column("Commands", "description",
                                :value_type => "Text"),
      }
      token_filters = [
        "TokenFilterStopWord",
        "TokenFilterStem",
      ]
      @diff.added_tables["Words"] = table("Words",
                                          :type => :pat_key,
                                          :key_type => "ShortText",
                                          :default_tokenizer => "TokenBigram",
                                          :normalizer => "NormalizerAuto",
                                          :token_filters => token_filters)
      @diff.added_columns["Words"] = {
        "commands_description" => column("Words", "commands_description",
                                         :type => :index,
                                         :flags => ["WITH_POSITION"],
                                         :value_type => "Commands",
                                         :sources => ["description"],
                                         :reference_value_type => true),
      }

      assert_equal(<<-LIST.gsub(/\\\n\s+/, ""), @diff.to_groonga_command_list)
table_create \\
  --flags "TABLE_HASH_KEY|KEY_LARGE" \\
  --key_type "ShortText" \\
  --name "Names" \\
  --normalizer "NormalizerAuto"

table_create \\
  --default_tokenizer "TokenBigram" \\
  --flags "TABLE_PAT_KEY" \\
  --key_type "ShortText" \\
  --name "Words" \\
  --normalizer "NormalizerAuto" \\
  --token_filters "TokenFilterStopWord|TokenFilterStem"

table_create \\
  --flags "TABLE_HASH_KEY" \\
  --key_type "Names" \\
  --name "Commands"
column_create \\
  --flags "COLUMN_SCALAR" \\
  --name "description" \\
  --table "Commands" \\
  --type "Text"

column_create \\
  --flags "COLUMN_INDEX|WITH_POSITION" \\
  --name "commands_description" \\
  --source "description" \\
  --table "Words" \\
  --type "Commands"
      LIST
    end
  end
end
