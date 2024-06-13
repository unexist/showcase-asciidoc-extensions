##
# @package Showcase-Asciidoc-Extensions
#
# @file Healthcheck block macro
# @copyright 2023-present Christoph Kappel <christoph@unexist.dev>
# @version $Id$
#
# This program can be distributed under the terms of the Apache License v1.0.
# See the file LICENSE for details.
##

require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'
require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'set'
require 'stringio'

include Asciidoctor
include ShowcaseEnv

class HealthcheckBlockMacro < Asciidoctor::Extensions::BlockMacroProcessor
    use_dsl

    named :healthcheck
    name_positional_attributes 'component', 'stage'

    @@CAPTURED_VALUES = []

    def process parent, target, attrs
        case target.upcase
        when 'BACKENDS'
            statusCode = handle_backends attrs

            create_pass_block(parent, HTML_SPAN % [
                200 == statusCode ? 'green' : 'red',
                200 == statusCode ? HTML_TICK : '%s (HTTP%d)' % [ HTML_CROSS, statusCode ],
            ], attrs)
        when 'STORE'
            fileName = '%s.csv' % [ attrs['filename'] || 'healthchecks' ]

            persist_data fileName
        when 'PLOT'
            fileName = '%s.csv' % [ attrs['filename'] || 'healthchecks' ]
            componentName = attrs['component'] || 'BLOG'
            content = plot_data fileName, componentName

            parse_content parent, content, attrs
        end
    end

    private

    def handle_backends attrs
        upComponent = attrs['component'].upcase rescue 'BLOG'
        upStage = attrs['stage'].upcase rescue 'DEV'
        statusCode = 500

        case upComponent
        when 'BLOG'
            if URL_BLOG.include? upStage
                statusCode = load_from_backend URL_BLOG[upStage]
            end
        when 'REDMINE'
            if URL_REDMINE.include? upStage
                statusCode = load_from_backend URL_REDMINE[upStage]
            end
        end

        store_data upComponent, upStage, statusCode

        statusCode
    end

    def get_status uri, headers = {}
        statusCode = 500

        begin
            request = Net::HTTP::Get.new uri

            headers.each do |key, value|
                request[key] = value
            end unless headers.nil?

            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: 'https' == uri.scheme) { |http|
                http.request request
            }

            case response
            when Net::HTTPSuccess
                statusCode = response.code.to_i

                unless 200 == statusCode
                    p "-" * 20, uri.to_s, response.body, "-" * 20
                end
            when Net::HTTPRedirection
                statusCode = get_status URI.parse(response['location']), headers rescue 500
            end
        rescue => err
            error_log err
        end

        statusCode
    end

    def load_from_backend url, apiKey = nil
        get_status URI.parse(url), {
            'accept' => 'application/json',
            'API-Key' => apiKey,
        } rescue 500
    end

    def store_data component, stage, statusCode
        @@CAPTURED_VALUES << {
            component: component,
            stage: stage,
            statusCode: statusCode
        }
    end

    def persist_data fileName
        begin
            File.open(fileName, 'a+') do |f|
                timeNow = Time.now.to_i

                @@CAPTURED_VALUES.each do | v |
                    f.puts '%d,%s,%s,%d' % [ timeNow, v[:component], v[:stage], v[:statusCode] ]
                end
            end
        rescue => err
            error_log err
        end

        nil
    end

    def plot_data fileName, componentName
        histData = {}
        histStages = Set.new

        # Load and sift data
        begin
            File.open(fileName, 'r') do |f|
                f.each_line do |line|
                    atTime, component, stage, statusCode = line.split ','

                    if componentName.upcase == component.upcase
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
        rescue => err
            error_log err
        end

        # Plotting time
        buffer = StringIO.new
        buffer.puts '[plantuml]'
        buffer.puts '----'

        histStages.each do |stage|
            buffer.puts 'robust "%s" as %s' % [ stage, stage ]
        end

        buffer.puts

        histData.each do |key, value|
            buffer.puts '@%s' % key

            value.sort { |a, b| a[:statusCode] <=> b[:statusCode] }

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
        block_macro HealthcheckBlockMacro
    end
end