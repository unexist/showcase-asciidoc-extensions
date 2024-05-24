require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'
require 'net/http'
require 'uri'
require 'json'
require 'date'

include Asciidoctor
include CESentryEnv
##
# @package Showcase-Asciidoc-Extensions
#
# @file Healthcheck inline macro
# @copyright 2024-present Christoph Kappel <christoph@unexist.dev>
# @version $Id$
#
# This program can be distributed under the terms of the Apache License v2.0.
# See the file LICENSE for details.
##

class HealthcheckInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
    use_dsl

    named :healthcheck
    name_positional_attributes 'component', 'stage'

    HTML_SPAN = '<span style="width: 100%%; height: 100%%; display: inline-block; background-color: %s">%s</span>'

    def process parent, target, attrs
        case target
        when 'backends'
            isAlive = handle_backends(attrs)
            create_inline_pass(parent, HTML_SPAN % [(isAlive ? 'green' : 'red'), isAlive ? '(/)' : '(x)'])
        end
    end

    private

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

    def get_status uri, headers = {}
        isAlive = false

        begin
            request = Net::HTTP::Get.new uri

            headers.each do |key, value|
                request[key] = value
            end unless headers.nil?

            response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: 'https' == uri.scheme) { |http|
                http.request request
            }

            unless response.nil? and 200 != response.code.to_i
                isAlive = true
            end
        rescue => err
            p err
        end

        isAlive
    end

    def load_from_backend url, apiKey = nil
        get_status URI.parse(url), {
            'accept' => 'application/json',
            'API-Key' => apiKey,
        } rescue false
    end
end

Asciidoctor::Extensions.register do
    if @document.basebackend? 'html'
        inline_macro HealthcheckInlineMacro
    end
end