##
# @package Showcase-Asciidoc-Extensions
#
# @file Healthplot block macro
# @copyright 2023-present Christoph Kappel <christoph@unexist.dev>
# @version $Id$
#
# This program can be distributed under the terms of the Apache License v1.0.
# See the file LICENSE for details.
##

require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'
require 'date'
require 'set'
require 'stringio'

include Asciidoctor
include ShowcaseEnv

class HealthplotBlockMacro < Extensions::BlockMacroProcessor
    use_dsl

    named :healthplot
    name_positional_attributes 'component', 'stage'

    def process parent, target, attrs
        fileName = '%s.csv' % [ attrs['filename'] || 'healthchecks' ]
        componentName = attrs['component'] || 'BLOG'
        content = plot_data fileName, componentName

        parse_content parent, content, attrs
    end

    private

    def plot_data fileName, componentName
        histData = {}
        histStages = Set.new

        # Load and sift data
        File.open(fileName, 'r') do |f|
            f.each_line do |line|
                atTime, component, stage, statusCode = line.split ',' rescue []

                if (componentName.upcase rescue 'BLOG') == component.upcase
                    formattedDate = Time.at(atTime.to_i).to_datetime.strftime('%Y/%m/%d') rescue '9999/9/9'

                    histData[formattedDate] ||= Set.new
                    histData[formattedDate] << {
                        stage: stage,
                        statusCode: statusCode,
                    }
                    histStages << stage
                end
            end
        end

        # Plotting time
        buffer = StringIO.new
        buffer.puts '.%s' % componentName.capitalize
        buffer.puts '[plantuml]'
        buffer.puts '----'

        histStages.each do |stage|
            buffer.puts 'robust "%s" as %s' % [ stage, stage ]
        end

        buffer.puts

        histData.each do |key, value|
            buffer.puts '@%s' % key

            value.each do |v|
                buffer.puts '%s is HTTP%s' % [ v[:stage], v[:statusCode] ]
            end

            buffer.puts
        end

        buffer.puts '----'

        buffer.string
    end
end

Asciidoctor::Extensions.register do
    if @document.basebackend? 'html'
        block_macro HealthplotBlockMacro
    end
end