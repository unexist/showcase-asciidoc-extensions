##
# @package Showcase-Asciidoc-Extensions
#
# @file Encironment to check
# @copyright 2024-present Christoph Kappel <christoph@unexist.dev>
# @version $Id$
#
# This program can be distributed under the terms of the Apache License v2.0.
# See the file LICENSE for details.
##

module ShowcaseEnv
    URL_APPSTORE = {
        'PLAYSTORE' => 'https://play.google.com/store/apps/details?id=com.google.android.apps.maps',
        'APPSTORE' => 'https://itunes.apple.com/lookup?id=585027354',
    }

    URL_BLOG = {
        'DEV' => 'https://unexist.blog',
        'TEST' => 'https://unexist.blog',
        'STAGING' => 'https://unexist.blog',
        'PROD' => 'https://unexist.blog',
    }

    URL_REDMINE = {
        'DEV' => 'https://subtle.de',
        'TEST' => 'https://subtle.de',
        'STAGING' => 'https://subtle.de',
        'PROD' => 'https://subtle.de',
    }

    HTML_SPAN = '<span style="width: 100%%; height: 100%%; display: inline-block; color: %s">%s</span>'
    HTML_TICK = '<ac:emoticon ac:name="tick" />'
    HTML_CROSS = '<ac:emoticon ac:name="cross" />'

    def error_log err
        p "Exception occurred #{err.class}. Message: #{err.message}. Backtrace:  \n #{err.backtrace.join('\n')}"
    end
end
