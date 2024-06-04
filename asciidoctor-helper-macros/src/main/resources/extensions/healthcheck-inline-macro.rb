##
# @package Showcase-Asciidoc-Extensions
#
# @file Healthcheck inline macro
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

include Asciidoctor
include ShowcaseEnv

class HealthcheckInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl

    named :healthcheck
    name_positional_attributes 'component', 'stage'

    def process parent, target, attrs
        case target
        when 'backends'
            statusCode = handle_backends(attrs)

            create_inline_pass(parent, HTML_SPAN % [
                200 == statusCode ? 'green' : 'red',
                200 == statusCode ? HTML_TICK : '%s (HTTP %d)' % [ HTML_CROSS, statusCode ],
            ])
        end
    end

    private

    def handle_backends attrs
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

            unless response.nil?
                statusCode = response.code.to_i

                unless 200 == statusCode
                    p "-" * 20, uri.to_s, response.body, "-" * 20
                end
            end
        rescue => err
            p err
        end

        statusCode
    end

    def load_from_backend url, apiKey = nil
        get_status URI.parse(url), {
            'accept' => 'application/json',
            'API-Key' => apiKey,
        } rescue 500
    end
end

Asciidoctor::Extensions.register do
    if @document.basebackend? 'html'
        inline_macro HealthcheckInlineMacro
    end
end