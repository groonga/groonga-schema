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

class PluginTest < Test::Unit::TestCase
  sub_test_case "#==" do
    test "equal" do
      plugin1 = GroongaSchema::Plugin.new("token_filters/stem")
      plugin2 = GroongaSchema::Plugin.new("token_filters/stem")
      assert_equal(plugin1, plugin2)
    end

    test "not equal" do
      plugin1 = GroongaSchema::Plugin.new("token_filters/stem")
      plugin2 = GroongaSchema::Plugin.new("token_filters/stop_word")
      assert_not_equal(plugin1, plugin2)
    end
  end

  test "#to_register_groonga_command" do
    plugin = GroongaSchema::Plugin.new("token_filters/stem")
    assert_equal("plugin_register --name \"token_filters/stem\"",
                 plugin.to_register_groonga_command.to_command_format)
  end

  test "#to_unregister_groonga_command" do
    plugin = GroongaSchema::Plugin.new("token_filters/stem")
    assert_equal("plugin_unregister --name \"token_filters/stem\"",
                 plugin.to_unregister_groonga_command.to_command_format)
  end
end
