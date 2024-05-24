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
include CESentryEnv

class CheckversionInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl

    named :checkversion
    name_positional_attributes 'component', 'os', 'stage'

    def process parent, target, attrs
        case target
        when 'apps'
            create_inline_pass parent, handle_apps(attrs)
        when 'backends'
            create_inline_pass parent, handle_backends(attrs)
        end
    end

    private

    def handle_apps(attrs)
        case attrs['component']
        when 'maps'
            case attrs['stage']
            when 'appstore'
                case attrs['os']
                when 'android'
                    load_from_playstore URL_APPSTORE_ANDROID
                when 'ios'
                    load_from_appstore URL_APPSTORE_IOS
                end
            end
        end
    end

    def handle_backends(attrs)
        case attrs['component']
        when 'blog'
            if URL_BLOG.include? attrs['stage'].upcase
                load_from_backend URL_BLOG[attrs['stage'].upcase]
            end
        when 'redmine'
            if URL_REDMINE.include? attrs['stage'].upcase
                load_from_backend URL_REDMINE[attrs['stage'].upcase]
            end
        end
    end

    def fetch_data uri, headers = {}
        retVal = ''

        begin
            request = Net::HTTP::Get.new uri

            headers.each do |key, value|
                request[key] = value
            end unless headers.nil?

            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: 'https' == uri.scheme) { |http|
                http.request request
            }

            unless response.nil? and 200 != response.code.to_i
                retVal = response.body
            end
        rescue => err
            p err
        end

        retVal
    end

    def load_from_appstore url
        data = fetch_data URI.parse(url), {
            'accept' => 'application/json'
        }

        JSON.parse(data)['results'].first['version'].gsub(/[^0-9\.]/, '') rescue "x.x"
    end

    def load_from_playstore url
        retVal = ''
        data = fetch_data URI.parse(url)

        data.scan(/<script nonce=\"\S+\">AF_initDataCallback\((.*?)\);/) do |match|
            begin
                matches = match.first.scan(/(\d+\.\d+\.\d+)/)

                retVal = matches.first.first unless matches.nil? or matches.empty?
            rescue => err
                p err
                retVal = 'x.x'
            end unless match.nil?
        end unless data.nil?

        retVal
    end

    def load_from_backend url, apiKey = nil
        data = fetch_data URI.parse(url), {
            'accept' => 'application/json',
            'API-Key' => apiKey,
        }

        JSON.parse(data)['version'].gsub(/[^0-9\.]/, '') rescue "x.x"
    end
end

Asciidoctor::Extensions.register do
    if @document.basebackend? 'html'
        inline_macro CheckversionInlineMacro
    end
end