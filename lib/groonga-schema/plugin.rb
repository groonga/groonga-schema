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

require "groonga/command"

module GroongaSchema
  class Plugin
    attr_reader :name
    def initialize(name)
      @name = name
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      @name == other.name
    end

    def to_register_groonga_command
      Groonga::Command::PluginRegister.new(:name => @name)
    end

    def to_unregister_groonga_command
      Groonga::Command::PluginUnregister.new(:name => @name)
    end
  end
end
