/**
 * @package Showcase-Asciidoc-Extensions
 *
 * @file Registry helper
 * @copyright 2024-present Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the Apache License v2.0.
 * See the file LICENSE for details.
 **/

package dev.unexist.asciidoctor;

import org.asciidoctor.Asciidoctor;
import org.asciidoctor.jruby.extension.spi.ExtensionRegistry;

public class HelperRegistry implements ExtensionRegistry {

    @Override
    public void register(Asciidoctor asciidoctor) {
        asciidoctor.rubyExtensionRegistry()
            .loadClass(HelperRegistry.class.getResourceAsStream("/extensions/env.rb"))
            .loadClass(HelperRegistry.class.getResourceAsStream("/extensions/checkversion-inline-macro.rb"))
            .inlineMacro("checkversion", "CheckversionInlineMacro")
            .loadClass(HelperRegistry.class.getResourceAsStream("/extensions/healthcheck-inline-macro.rb"))
            .inlineMacro("healthcheck", "HealthcheckInlineMacro");
    }
}