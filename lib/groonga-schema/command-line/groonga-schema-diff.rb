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

require "optparse"
require "uri"
require "open-uri"

require "groonga/command/parser"

require "groonga-schema/differ"

module GroongaSchema
  module CommandLine
    class GroongaSchemaDiff
      class << self
        def run(args=ARGV)
          new(args).run
        end
      end

      def initialize(args)
        @args = args
        @format = :command
      end

      def run
        parse_arguments

        from_schema = parse_schema(@from)
        to_schema = parse_schema(@to)
        differ = GroongaSchema::Differ.new(from_schema, to_schema)
        diff = differ.diff
        $stdout.print(diff.to_groonga_command_list(:format => @format))

        if diff.same?
          0
        else
          1
        end
      end

      private
      def parse_arguments
        parser = OptionParser.new
        parser.banner += " FROM_SCHEMA TO_SCHEMA"

        available_formats = [:command, :uri]
        parser.on("--format=FORMAT", available_formats,
                  "Specify output Groonga command format.",
                  "Available formats: #{available_formats.join(", ")}",
                  "(#{@format})") do |format|
          @format = format
        end

        rest_args = parser.parse(@args)

        if rest_args.size != 2
          $stderr.puts("Error: Both FROM_SCHEMA and TO_SCHEMA are required.")
          $stderr.puts(parser.help)
          exit(false)
        end
        @from, @to = rest_args
      end

      def parse_schema(resource_path)
        open_resource(resource_path) do |resource|
          schema = GroongaSchema::Schema.new
          parser = Groonga::Command::Parser.new
          parser.on_command do |command|
            schema.apply_command(command)
          end
          parser.on_load_value do |command,|
            command.original_source.clear
          end
          resource.each_line do |line|
            parser << line
          end
          parser.finish
          schema
        end
      end

      def open_resource(resource_path)
        uri = nil
        begin
          uri = URI.parse(resource_path)
        rescue URI::InvalidURIError
        end

        if uri and uri.respond_to?(:open)
          uri.open do |response|
            yield(response)
          end
        else
          File.open(resource_path) do |file|
            yield(file)
          end
        end
      end
    end
  end
end
