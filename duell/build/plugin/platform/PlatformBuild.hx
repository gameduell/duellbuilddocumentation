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

package duell.build.plugin.platform;

import duell.helpers.LogHelper;
import haxe.io.Error;
import sys.FileSystem;
import duell.objects.Haxelib;
import duell.build.objects.Configuration;
import duell.build.objects.DuellProjectXML;
import duell.build.plugin.platform.PlatformConfiguration;
import duell.helpers.CommandHelper;
import duell.helpers.ImportHelper;
import duell.helpers.PathHelper;
import duell.helpers.PlatformHelper.Platform;
import duell.helpers.TemplateHelper;
import duell.objects.Arguments;
import duell.objects.DuellLib;
import haxe.io.Path;
import sys.io.File;


using StringTools;

class PlatformBuild
{
    public var requiredSetups = [];
    public var supportedHostPlatforms = [Platform.WINDOWS, Platform.MAC, Platform.LINUX];

    private var targetDirectory: String;
    private var projectDirectory: String;
    private var mainDirectory: String;
    private var templateDirectory: String;
    private var documentationXMLName: String;

    private var documentationPlatform: Platform;

    public function new()
    {
        checkArguments();
    }

    private function checkArguments(): Void
    {
        if (Arguments.isSet("-android"))
        {
            Configuration.addParsingDefine("android");
            Configuration.addParsingDefine("cpp");
            documentationPlatform = Platform.ANDROID;
        }
        else if (Arguments.isSet("-flash"))
        {
            Configuration.addParsingDefine("flash");
            documentationPlatform = Platform.FLASH;
        }
        else if (Arguments.isSet("-html5"))
        {
            Configuration.addParsingDefine("html5");
            documentationPlatform = Platform.HTML5;
        }
        else if (Arguments.isSet("-ios"))
        {
            Configuration.addParsingDefine("ios");
            Configuration.addParsingDefine("cpp");
            documentationPlatform = Platform.IOS;
        }
        else
        {
            Configuration.addParsingDefine("html5");
            documentationPlatform = Platform.HTML5;
        }

        Configuration.addParsingDefine("release");
        Configuration.addParsingDefine("nodce");
    }

    public function parse(): Void
    {
        parseProject();
    }

    public function parseProject(): Void
    {
        var projectXML: DuellProjectXML = DuellProjectXML.getConfig();
        projectXML.parse();
    }

    public function prepareBuild() : Void
    {
        prepareVariables();
        prepareDoxLibrary();
        prepareConfiguration();
        prepareDocumentation();
        prepareCompilationFlags();
        prepareDocumentationBuild();
    }

    private function prepareVariables(): Void
    {
        targetDirectory = Configuration.getData().OUTPUT;
        projectDirectory = Path.join([targetDirectory, "documentation"]);
        mainDirectory = Path.join([DuellLib.getDuellLib("duellbuilddocumentation").getPath(), "documentation"]);
        templateDirectory = Path.join([DuellLib.getDuellLib("duellbuilddocumentation").getPath(), "template"]);
        documentationXMLName = "documentation_raw_" + Std.string(documentationPlatform) + ".xml";
    }

    private function prepareDoxLibrary(): Void
    {
        if (Haxelib.getHaxelib("dox", "1.0.0").exists())
        {
            return;
        }

        Haxelib.getHaxelib("dox", "1.0.0").install();
    }

    private function prepareConfiguration(): Void
    {
        Configuration.getData().MAIN = "MainImportAll";
        Configuration.getData().SOURCES.push(mainDirectory);
    }

    private function prepareDocumentation(): Void
    {
        var docuRoot: String = Path.join([Configuration.getData().OUTPUT, "documentation", "generated", "documentation"]);

        PathHelper.removeDirectory(docuRoot);
    }

    private function prepareCompilationFlags(): Void
    {
        convertHaxeLibsIntoCompilationFlags();
        convertDuellLibsIntoCompilationFlags();
        convertMainDirectoryIntoCompilationFlag();
        convertParsingDefinesToCompilationDefines();
        convertImportAllDefinesIntoCompilationFlags();

        forceHaxeJson();
        forceDeprecationWarnings();
        forceDocumentationGeneration();
    }

    private function convertHaxeLibsIntoCompilationFlags(): Void
    {
        for (haxelib in Configuration.getData().DEPENDENCIES.HAXELIBS)
        {
            var version = haxelib.version;

            if (version.startsWith("ssh") || version.startsWith("http"))
            {
                version = "git";
            }

            Configuration.getData().HAXE_COMPILE_ARGS.push("-lib " + haxelib.name + (version != "" ? ":" + version : ""));
        }
    }

    private function convertDuellLibsIntoCompilationFlags(): Void
    {
        for (source in Configuration.getData().SOURCES)
        {
            var compilerFlag: String = "-cp " + source;

            if (Configuration.getData().HAXE_COMPILE_ARGS.indexOf(compilerFlag) == -1)
            {
                Configuration.getData().HAXE_COMPILE_ARGS.push(compilerFlag);
            }
        }

        for (duelllib in PlatformConfiguration.getData().LIBRARIES)
        {
            var compilerFlag: String = "-cp " + DuellLib.getDuellLib(duelllib.name, "master").getPath();

            if (Configuration.getData().HAXE_COMPILE_ARGS.indexOf(compilerFlag) == -1)
            {
                Configuration.getData().HAXE_COMPILE_ARGS.push(compilerFlag);
            }
        }
    }

    private function convertMainDirectoryIntoCompilationFlag(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + mainDirectory);
    }

    private function convertParsingDefinesToCompilationDefines()
    {
        for (define in DuellProjectXML.getConfig().parsingConditions)
        {
            if (define == "cpp") /// not allowed
            {
                LogHelper.warn("Documentation generation is not tested with cpp targets");
                continue;
            }

            switch (define)
            {
                case "android":
                    Configuration.getData().HAXE_COMPILE_ARGS.push("-cpp build/android");
                case "flash":
                    Configuration.getData().HAXE_COMPILE_ARGS.push("-swf build/flash");
                case "html5":
                    Configuration.getData().HAXE_COMPILE_ARGS.push("-js build/html5");
                case "ios":
                    Configuration.getData().HAXE_COMPILE_ARGS.push("-cpp build/ios");
            }

            Configuration.getData().HAXE_COMPILE_ARGS.push("-D " + define);
        }
    }

    private function convertImportAllDefinesIntoCompilationFlags(): Void
    {
        for (duellLib in PlatformConfiguration.getData().LIBRARIES)
        {
            var importAllDefines: Array<ImportAllDefine> = ImportHelper.getImportAllDefinesRecursively(duellLib.name);

            for (importAllDefine in importAllDefines)
            {
                var compilerFlagDocumentation: String = '-cp ' + importAllDefine.documentationFolder;
                var compilerFlagLibrary: String = '-cp ' + DuellLib.getDuellLib(importAllDefine.libraryName).getPath();

                if (Configuration.getData().HAXE_COMPILE_ARGS.indexOf(compilerFlagDocumentation) == -1)
                {
                    Configuration.getData().HAXE_COMPILE_ARGS.push(compilerFlagDocumentation);
                }

                if (Configuration.getData().HAXE_COMPILE_ARGS.indexOf(compilerFlagLibrary) == -1)
                {
                    Configuration.getData().HAXE_COMPILE_ARGS.push(compilerFlagLibrary);
                }

                if (PlatformConfiguration.getData().IMPORTS.indexOf(importAllDefine.importAllPackage) == -1)
                {
                    PlatformConfiguration.getData().IMPORTS += "import " + importAllDefine.importAllPackage + ".ImportAll;\n";
                }
            }
        }
    }

    private function forceHaxeJson(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push("-D haxeJSON");
    }

    private function forceDeprecationWarnings(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push("-D deprecation-warnings");
    }

    private function forceDocumentationGeneration()
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push('-cp ' + Path.join([projectDirectory, "generated"]));
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $documentationXMLName');
        Configuration.getData().HAXE_COMPILE_ARGS.push('--cwd ../generated');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-cmd haxelib run dox -i $documentationXMLName');
    }

    private function prepareDocumentationBuild() : Void
    {
        createDirectoryAndCopyTemplate();
        generateMainImportAllFile();
    }

    private function createDirectoryAndCopyTemplate() : Void
    {
        /// Create directories
        PathHelper.mkdir(targetDirectory);

        ///copying template files
        TemplateHelper.recursiveCopyTemplatedFiles(Path.join([templateDirectory, "documentation"]),
                                                             projectDirectory,
                                                             Configuration.getData(),
                                                             Configuration.getData().TEMPLATE_FUNCTIONS);
    }

    private function generateMainImportAllFile(): Void
    {
        var mainContent: String = "\nclass MainImportAll\n{\n    static public function main(): Void\n    {}\n}";

        var fullContent: String = PlatformConfiguration.getData().IMPORTS + mainContent;
        File.saveContent(Path.join([projectDirectory, "generated", "MainImportAll.hx"]), fullContent);
    }

    public function build(): Void
    {
        var buildPath : String  = Path.join([Configuration.getData().OUTPUT, "documentation", "hxml"]);

        var result = CommandHelper.runHaxe( buildPath,
                                            ["Build.hxml"],
                                            {
                                                logOnlyIfVerbose : false,
                                                systemCommand : true,
                                                errorMessage: "compiling the haxe code",
                                                exitOnError: true
                                            });
    }

    // COMMON STUFF!
    public function postParse(): Void
    {}

    public function preBuild(): Void
    {}

    public function postBuild(): Void
    {}

    public function publish(): Void
    {}

    public function test(): Void
    {}

    public function run(): Void
    {}

    public function handleError(): Void
    {}

    public function fast(): Void
    {}

    public function clean(): Void
    {}
}
