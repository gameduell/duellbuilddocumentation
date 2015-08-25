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

package;

import haxe.Json;
import haxe.Json;
import dox.Config;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import dox.Dox;

typedef DocDefine = {
    title: String,
    xmlPath: String,
    themePath: String,
    outputPath: String,
    topLevelPackages: Array<String>,
}

class DoxRunner
{
    inline static private var DOX_CFG: String = "DoxConfig.json";   // File

    static private var instance: DoxRunner = null;

    private var rebuildStd: Bool;

    private var stdDocDef: DocDefine;
    private var mainDocDef: DocDefine;

    public function new(): Void
    {}

    static public function main(): Void
    {
        initiate();
        instance.start();
    }

    static private function initiate(): Void
    {
        if (instance == null)
            instance = new DoxRunner();
    }

    static public function getInstance(): DoxRunner
    {
        return instance;
    }

    private function start(): Void
    {
        var jsonPath = Path.join([Sys.getCwd(), DOX_CFG]);

        if (!FileSystem.exists(jsonPath))
        {
            Sys.println('IE/DOX_RUNNER: Missing $jsonPath');
            return;
        }

        assignDoxConfig(jsonPath);

        Dox.initiate();

        if (rebuildStd)
        {
            Sys.println("Rebuild Haxe Std documentation...");
            Dox.getInstance().start(createStdConfig());
        }
        else if (!FileSystem.exists(stdDocDef.outputPath))
        {
            Sys.println("Haxe Std documentation generation forced");
            Dox.getInstance().start(createStdConfig());
        }

        Dox.getInstance().start(createMainConfig());
    }

    private function assignDoxConfig(path: String): Void
    {
        var json = Json.parse(File.getContent(path));

        rebuildStd = json.rebuildStd;
        stdDocDef = json.docStd;
        mainDocDef = json.docMain;
    }

    private function createMainConfig(): Config
    {
        var cfgMain = new Config();

        cfgMain.pageTitle = mainDocDef.title;
        cfgMain.defines["stdRoot"] = stdDocDef.outputPath;
        cfgMain.outputPath = mainDocDef.outputPath;
        cfgMain.xmlPath = mainDocDef.xmlPath;
        cfgMain.assignTheme(mainDocDef.themePath);

        for (lib in mainDocDef.topLevelPackages)
        {
            cfgMain.topLevelPackages.push(lib);
        }

        return cfgMain;
    }

    private function createStdConfig(): Config
    {
        var cfgStd = new Config();

        cfgStd.pageTitle = stdDocDef.title;
        cfgStd.defines["version"] = "3.2.0";
        cfgStd.defines["source-path"] = "https://github.com/HaxeFoundation/haxe/blob/development/std/";
        cfgStd.outputPath = stdDocDef.outputPath;
        cfgStd.xmlPath = stdDocDef.xmlPath;
        cfgStd.addFilter("microsoft", false);
        cfgStd.addFilter("javax", false);
        cfgStd.addFilter("cs.internal", false);
        cfgStd.assignTheme(stdDocDef.themePath);

        return cfgStd;
    }
}