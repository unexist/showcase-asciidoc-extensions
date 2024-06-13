##
# @package Showcase-Asciidoc-Extensions
#
# @file Checkversion inline macro
# @copyright 2024-present Christoph Kappel <christoph@unexist.dev>
# @version $Id$
#
# This program can be distributed under the terms of the Apache License v2.0.
# See the file LICENSE for details.
##

require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'
require 'net/http'
require 'uri'
require 'json'
require 'date'

include Asciidoctor
include ShowcaseEnv

class CheckversionInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl

    named :checkversion
    name_positional_attributes 'component', 'os', 'stage'

    def process parent, target, attrs
        statusCode = 500
        versionString = 'x.x'

        case target
        when 'apps'
            statusCode, versionString = handle_apps attrs
        when 'backends'
            statusCode, versionString = handle_backends attrs
        end

        create_inline_pass parent, (200 == statusCode ? versionString : '%s (HTTP%d)' % [
            versionString, statusCode
        ])
    end

    private

    def handle_apps attrs
        upComponent = attrs['component'].upcase rescue 'MAPS'
        upStage = attrs['stage'].upcase rescue 'APPSTORE'
        upOs = attrs['os'].upcase rescue 'ANDROID'


        case upComponent
        when 'MAPS'
            case upStage
            when 'APPSTORE'
                case upOs
                when 'ANDROID'
                    load_from_playstore URL_APPSTORE_ANDROID
                when 'IOS'
                    load_from_appstore URL_APPSTORE_IOS
                end
            end
        end
    end

    def handle_backends attrs
        upComponent = attrs['component'].upcase rescue 'BLOG'
        upStage = attrs['stage'].upcase rescue 'DEV'
        retVal = [ 500, '' ]

        case upComponent
        when 'BLOG'
            if URL_BLOG.include? upStage
                retVal = load_from_backend URL_BLOG[upStage], ENV['API-KEY']
            end
        when 'REDMINE'
            if URL_REDMINE.include? upStage
                retVal = load_from_backend URL_REDMINE[upStage], ENV['API-KEY']
            end
        end

        retVal
    end

    def fetch_data uri, headers = {}
        statusCode = 500
        retVal = ''

        begin
            request = Net::HTTP::Get.new uri

            headers.each do |key, value|
                request[key] = value
            end unless headers.nil?

            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: 'https' == uri.scheme) { |http|
                http.request request
            }

            unless response.nil?
                statusCode = response.code.to_i
                retVal = response.body

                unless 200 == statusCode
                    p "-" * 20, uri, response.body, "-" * 20
                end
            end
        rescue => err
            error_log err
        end

        [ statusCode, retVal ]
    end

    def load_from_appstore url
        statusCode, data = fetch_data URI.parse(url), {
            'accept' => 'application/json'
        }
        versionString = JSON.parse(data)['results'].first['version'].gsub(/[^0-9\.]/, '') rescue 'x.x'

        [ statusCode, versionString ]
    end

    def load_from_playstore url
        data = fetch_data URI.parse(url)
        versionString = 'x.x'

        data.scan(/<script nonce=\"\S+\">AF_initDataCallback\((.*?)\);/) do |match|
            begin
                matches = match.first.scan(/(\d+\.\d+\.\d+)/)

                versionString = matches.first.first unless matches.nil? or matches.empty?
            rescue => err
                error_log err
            end unless match.nil?
        end unless data.nil?

        [ statusCode, versionString ]
    end

    def load_from_backend url, apiKey = nil
        statusCode, jsonData = fetch_data URI.parse(url), {
            'accept' => 'application/json',
            'API-Key' => apiKey,
        }
        versionString = JSON.parse(jsonData)['version'].gsub(/[^0-9\.]/, '') rescue 'x.x'

        [ statusCode, versionString ]
    end
end

Asciidoctor::Extensions.register do
    if @document.basebackend? 'html'
        inline_macro CheckversionInlineMacro
    end
end