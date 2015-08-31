/*
 * Copyright (c) 2003-2015, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package dox;

import dox.helper.PathHelper;
import dox.helper.StdHelper;
import dox.helper.XMLHelper;
import haxe.io.Path;
import haxe.rtti.CType.TypeRoot;
import haxe.rtti.XmlParser;
import haxe.Timer;
import sys.FileSystem;
import sys.io.File;

class Dox
{
    static private var instance: Dox = null;

    private var config: Config;
    private var parser: XmlParser;
    private var writer: Writer;

    private var tStart: Float;

    public function new()
    {}

    static public function initiate(): Void
    {
        if (instance != null)
            return;

        instance = new Dox();
    }

    static public function getInstance(): Dox
    {
        return instance;
    }

    public function start(cfg: Config): Void
    {
        tStart = 0.0;
        parser = new XmlParser();

        if (cfg == null)
            exit('IE/Dox: Passed Config is null. Dox aborted', 1);
        else
            config = cfg;

        writer = new Writer(config);
        tStart = Timer.stamp();

        if (!FileSystem.exists(config.xmlPath))
            exit('IE/Dox: Could not read input path ${config.xmlPath}', 1);

        var xmls = XMLHelper.findXmls(config.xmlPath);

        for (key in xmls.keys())
        {
            if (xmls[key] == null)
                continue;

            parser.process(xmls[key], key);
            config.platforms.push(key);
        }

        if (config.platforms.length == 0)
            exit('IE/Dox: Xml input is empty or invalid!', 1);

        Sys.println('Clear docs output folder: ${config.outputPath}');
        PathHelper.clearDir(config.outputPath);

        if (config.toplevelPackages.length == 0)
            generate();
        else
            generatePackages();

        Sys.println('Done after ${Timer.stamp() - tStart} Seconds');
    }

    private function generatePackages(): Void
    {
        createHome();

        var owd = config.outputPath;
        config.homePath += "../";

        for (pack in config.toplevelPackages)
        {
            if (pack == "")
                continue;

            config.pack = pack;
            config.pageTitle = pack;
            config.outputPath = Path.join([owd, pack]);
            config.removeAllFilter();
            config.addFilter(pack, true);

            var dups: Array<String> = config.toplevelPackages.filter(function(s) {
               if (s != pack && s.indexOf(pack) != -1)
                   return true;
                return false;
            });

            for (dup in dups) config.addFilter(dup, false);

            generate();
        }
    }

    private function generate(): Void
    {
        Sys.println("Processing types");
        var proc = new Processor(config);
        var root = proc.process(parser.root);

        var api = new Api(config, proc.infos);
        var gen = new Generator(api, writer);

        Sys.println("");
        Sys.println("Generating navigation");
        gen.generateNavigation(root);

        Sys.println('Generating to ${config.outputPath}');
        gen.generate(root);

        Sys.println("");
        Sys.println('Generated ${api.infos.numGeneratedTypes} types in ${api.infos.numGeneratedPackages} packages');

        for (dir in config.resourcePaths)
        {
            Sys.println('Copying resources from $dir');
            writer.copyFrom(dir);
        }

        writer.finalize();
    }

    private function createHome(): Void
    {
        var templateRootNav: templo.Template = config.loadTemplate("nav_root.mtt");
        var templateRootMain: templo.Template = config.loadTemplate("main_root.mtt");

        var rootNav = templateRootNav.execute({libs: config.toplevelPackages});
        var rootMain = templateRootMain.execute({api: new Api(config, null)});

        writer.saveContent("nav.js", ~/[\r\n\t]/g.replace(rootNav, ""));
        writer.saveContent("index.html", ~/[\r\n\t]/g.replace(rootMain, ""));

        for (dir in config.resourcePaths)
        {
            Sys.println('Copying resources from $dir');
            writer.copyFrom(dir);
        }

        writer.finalize();
    }

    private function exit(msg: String, c: Int): Void
    {
        Sys.println(msg);
        Sys.exit(c);
    }
}
