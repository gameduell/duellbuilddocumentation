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

import duell.helpers.ImportAllHelper;
import logger.Logger;
import duell.build.objects.Configuration;
import duell.build.objects.DuellProjectXML;
import duell.build.plugin.platform.PlatformConfiguration.ImportAllDefine;
import duell.build.plugin.platform.PlatformConfiguration;
import duell.helpers.CommandHelper;
import duell.helpers.LogHelper;
import duell.helpers.PathHelper;
import duell.helpers.PlatformHelper.Platform;
import duell.helpers.TemplateHelper;
import duell.objects.Arguments;
import duell.objects.DuellLib;
import duell.objects.Haxelib;
import haxe.io.Error;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class PlatformBuild
{
    inline static private var EXP_DIR: String = "documentation";    // -Located in export root
    inline static private var GEN_DIR: String = "generated";        // --Located in docRoot
    inline static private var DOC_XML_DIR: String = "xml";          // ---Located in genRoot
    inline static private var STD_XML_DIR: String = "std";          // ----Located in DocXmlDir
    inline static private var MAIN_XML_DIR: String = "duell";       // ----Located in DocXmlDir
    inline static private var DOC_OUT_DIR: String = "dox";          // ---Located in genRoot
    inline static private var STD_OUT_DIR: String = "std";          // ----Located in DocOutDir
    inline static private var MAIN_OUT_DIR: String = "duell";       // ----Located in DocOutDir
    inline static private var README_DIR: String = "readme";        // ---Located in genRoot
    inline static private var BIN_DIR: String = "bin";              // --Located in docRoot
    inline static private var HXML_DIR: String = "hxml";            // --Located in docRoot

    inline static private var LIB_DIR: String = "duellbuilddocumentation";  // LibRoot Dir
    inline static private var TPL_DIR: String = "template";                 // -Located in libRoot
    inline static private var THEMES_DIR: String = "themes";                // -Located in libRoot
    inline static private var GENERATOR_DIR: String = "generator";          // -Located in libRoot

    inline static private var BUILD_HXML: String = "Build.hxml";    // Name of the build compiler file
    inline static private var DOX_HXML: String = "Dox.hxml";        // Name of the dox compiler file
    inline static private var MAIN_IA: String = "MainImportAll";    // Name of the main file (override)
    inline static private var STD_IA: String = "StdImportAll";      // Name of the main std file
    inline static private var DOX_CFG: String = "DoxConfig.json";   // Name of the DoxRunner config file
    inline static private var DOX_N: String = "Dox.n";              // Name of the DoxRunner neko file

    private var docRoot: String;    // Root folder for documentation export
    private var genRoot: String;    // Root folder for generated output
    private var binRoot: String;    // Root folder for bin files
    private var hxmlRoot: String;   // Root folder for .hxml files

    private var libRoot: String;        // Root folder for Documentation build tool
    private var tplRoot: String;        // Root folder for templates
    private var themesRoot: String;     // Root folder for themes
    private var generatorRoot: String;  // Root folder for generator libs

    private var stdOutRoot: String;     // Root folder for generated std documentation
    private var mainOutRoot: String;    // Root folder for generated main documentation

    private var mainXmlPath: String; // Full path to the generated .xml file (main documentation)
    private var stdXmlRoot: String;  // Root folder for std .xml files (std documentation)

    private var readmeRoot: String; // Root folder for readme files (named like library)

    private var doxHxmlPath: String;    // Full path to the dox.hxml file
    private var mainPath: String;       // Full path to the main file (.hx)
    private var doxCfgPath: String;     // Full path to the DoxRunner config file
    private var doxNPath: String;       // Full path to the DoxRunner neko file

    private var docPlatform: Platform;
    private var rebuildStd: Bool;
    private var theme: String;

    private var docPackages: Array<String> = [];
    private var importAllDefines: Array<ImportAllDefine> = [];

    public var requiredSetups: Array<{name: String, version: String}> = [];
    public var supportedHostPlatforms: Array<Platform> = [Platform.WINDOWS, Platform.MAC, Platform.LINUX];

    public function new()
    {
        checkArguments();
    }

    private function checkArguments(): Void
    {
        if (Arguments.isSet("-android"))
        {
            Configuration.addParsingDefine("android");
            docPlatform = Platform.ANDROID;
        }
        else if (Arguments.isSet("-flash"))
        {
            Configuration.addParsingDefine("flash");
            docPlatform = Platform.FLASH;
        }
        else if (Arguments.isSet("-html5"))
        {
            Configuration.addParsingDefine("html5");
            docPlatform = Platform.HTML5;
        }
        else if (Arguments.isSet("-ios"))
        {
            Configuration.addParsingDefine("ios");
            docPlatform = Platform.IOS;
        }
        else
        {
            Configuration.addParsingDefine("html5");
            docPlatform = Platform.HTML5;
        }

        if (Arguments.isSet("-rebuildStd"))
            rebuildStd = true;
        else
            rebuildStd = false;

        if (Arguments.isSet("-theme"))
            theme = Arguments.get("-theme");
        else
            theme = "default";

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
        prepareConfiguration();
        prepareImportAllDefines();
        prepareCompilationFlags();
        prepareDocumentationBuild();
    }

    private function prepareVariables(): Void
    {
        docRoot = Path.join([Configuration.getData().OUTPUT, EXP_DIR]);
        genRoot = Path.join([docRoot, GEN_DIR]);
        binRoot = Path.join([docRoot, BIN_DIR]);
        hxmlRoot = Path.join([docRoot, HXML_DIR]);

        libRoot = DuellLib.getDuellLib(LIB_DIR).getPath();
        tplRoot = Path.join([libRoot, TPL_DIR]);
        themesRoot = Path.join([libRoot, THEMES_DIR]);
        generatorRoot = Path.join([libRoot, GENERATOR_DIR]);

        stdOutRoot = Path.join([genRoot, DOC_OUT_DIR, STD_OUT_DIR]);
        mainOutRoot = Path.join([genRoot, DOC_OUT_DIR, MAIN_OUT_DIR, '$docPlatform']);

        stdXmlRoot = Path.join([genRoot, DOC_XML_DIR, STD_XML_DIR]);
        mainXmlPath = Path.join([genRoot, DOC_XML_DIR, MAIN_XML_DIR, '$docPlatform.xml']);

        readmeRoot = Path.join([genRoot, README_DIR]);

        doxHxmlPath = Path.join([hxmlRoot, DOX_HXML]);
        mainPath = Path.join([genRoot, '$MAIN_IA.hx']);
        doxCfgPath = Path.join([genRoot, DOX_CFG]);
        doxNPath = Path.join([genRoot, DOX_N]);
    }

    private function prepareConfiguration(): Void
    {
        Configuration.getData().MAIN = "MainImportAll";
    }

    private function prepareImportAllDefines()
    {
        for (libDef in PlatformConfiguration.getData().LIBRARIES)
        {
            importAllDefines = importAllDefines.concat(ImportAllHelper.getImportAllDefines(libDef.NAME));
        }
    }

    private function prepareCompilationFlags(): Void
    {
        convertHaxeLibsIntoCompilationFlags();
        convertDuellLibsIntoCompilationFlags();
        convertMainDirectoryIntoCompilationFlag();
        convertParsingDefinesToCompilationDefines();
        convertImportAllDefinesIntoCompilationFlags();

        forceHaxeJson();
        forceNoOutput();
        forceDeprecationWarnings();

        addDocGenerationFlags();
        addStdGenerationFlags();
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

            var arg = "-lib " + haxelib.name + (version != "" ? ":" + version : "");

            if (Configuration.getData().HAXE_COMPILE_ARGS.indexOf(arg) == -1)
                Configuration.getData().HAXE_COMPILE_ARGS.push(arg);
        }
    }

    private function convertDuellLibsIntoCompilationFlags(): Void
    {
        for (source in Configuration.getData().SOURCES)
        {
            var arg = '-cp $source';

            if (Configuration.getData().HAXE_COMPILE_ARGS.indexOf(arg) == -1)
                Configuration.getData().HAXE_COMPILE_ARGS.push(arg);
        }
    }

    private function convertMainDirectoryIntoCompilationFlag(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push('-cp $libRoot');
    }

    private function convertParsingDefinesToCompilationDefines()
    {
        for (define in DuellProjectXML.getConfig().parsingConditions)
        {
            switch (define)
            {
                case "android":
                    Configuration.getData().HAXE_COMPILE_ARGS.push('-cpp build/android');
                case "flash":
                    Configuration.getData().HAXE_COMPILE_ARGS.push('-swf build/flash');
                    continue; // flash flag is reserved
                case "html5":
                    Configuration.getData().HAXE_COMPILE_ARGS.push('-js build/html5');
                case "ios":
                    Configuration.getData().HAXE_COMPILE_ARGS.push('-cpp build/ios');
            }

            Configuration.getData().HAXE_COMPILE_ARGS.push('-D $define');
        }
    }

    private function convertImportAllDefinesIntoCompilationFlags(): Void
    {
        for (importAllDefine in importAllDefines)
        {
            var docArg = '-cp ${importAllDefine.DOC_ROOT}';
            var libArg = '-cp ${DuellLib.getDuellLib(importAllDefine.LIB).getPath()}';

            if (Configuration.getData().HAXE_COMPILE_ARGS.indexOf(docArg) == -1)
                Configuration.getData().HAXE_COMPILE_ARGS.push(docArg);

            if (Configuration.getData().HAXE_COMPILE_ARGS.indexOf(libArg) == -1)
                Configuration.getData().HAXE_COMPILE_ARGS.push(libArg);

            if (docPackages.indexOf(importAllDefine.DOC_PACKAGE) == -1)
                docPackages.push(importAllDefine.DOC_PACKAGE);

        }
    }

    private function forceNext(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push('--next');
    }

    private function forceHaxeJson(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D haxeJSON');
    }

    private function forceNoOutput(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push('--no-output');
    }

    private function forceDeprecationWarnings(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D deprecation-warnings');
    }

    private function addDocGenerationFlags()
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push('-cp $genRoot');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $mainXmlPath');
        Configuration.getData().HAXE_COMPILE_ARGS.push('--cwd $genRoot');

        // <-- Compile DoxRunner as neko file for continue the process there --> \\
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-cmd haxe $doxHxmlPath');
    }

    private function addStdGenerationFlags(): Void
    {
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-cmd cd $genRoot');
        forceNext();
        forceNoOutput();
        Configuration.getData().HAXE_COMPILE_ARGS.push('--cwd $binRoot');
        Configuration.getData().HAXE_COMPILE_ARGS.push('--macro $STD_IA.run()');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-dce no');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D doc-gen');
        Configuration.getData().HAXE_COMPILE_ARGS.push('--each');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-neko all.n');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/neko.xml');
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-js all.js');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/js.xml');
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-swf all9.swf');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/flash.xml');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-swf-version 11.4');
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-php all_php');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/php.xml');
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-cpp all_cp');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/cpp.xml');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D xmldoc');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D HXCPP_MULTI_THREADED');
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-java all_java');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/java.xml');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D xmldoc');
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-cs all_cs');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/cs.xml');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D unsafe');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D xmldoc');
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('-python all_py');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/python.xml');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-D xmldoc');
        forceNext();
        Configuration.getData().HAXE_COMPILE_ARGS.push('--interp');
        Configuration.getData().HAXE_COMPILE_ARGS.push('-xml $stdXmlRoot/macro.xml');
    }

    private function prepareDocumentationBuild() : Void
    {
        createDirectoryAndCopyTemplate();
        generateMainImportAllFile();
        generateDoxConfigFile();
        generateReadmeFiles();
        generateDoxHXML();
    }

    private function createDirectoryAndCopyTemplate() : Void
    {
        /// Create directories
        PathHelper.mkdir(Configuration.getData().OUTPUT);

        ///copying template files
        TemplateHelper.recursiveCopyTemplatedFiles(Path.join([tplRoot, "documentation"]),
                                                             docRoot,
                                                             Configuration.getData(),
                                                             Configuration.getData().TEMPLATE_FUNCTIONS);
    }

    private function generateMainImportAllFile(): Void
    {
        var importContent: String = [for (p in docPackages) 'import $p.ImportAll;'].join('\n');
        var classContent: String = "\nclass MainImportAll\n{\n    static public function main(): Void\n    {}\n}";
        var fullContent: String = 'package;\n$importContent\n$classContent';

        File.saveContent(mainPath, fullContent);
    }

    private function generateDoxConfigFile(): Void
    {
        if (!FileSystem.exists(Path.join([themesRoot, theme])))
        {
            LogHelper.warn('Cannot find theme \"$theme\" in \"$themesRoot\". Switch to theme \"default\"');
            theme = "default";
        }

        var libs: Array<String> = [for (libDef in PlatformConfiguration.getData().LIBRARIES) libDef.NAME];

        for (pack in PlatformConfiguration.getData().IMPORTALL)
        {
            if (libs.indexOf(pack.LIB) != -1)
                libs[libs.indexOf(pack.LIB)] = pack.DOC_PACKAGE;
        }

        function sortAlphabetically(a: String, b: String, index: Int = 0): Int
        {
            var ac = a.toLowerCase().charCodeAt(index);
            var bc = b.toLowerCase().charCodeAt(index);
            if (ac == null)
                return -1;
            else if (bc == null)
                return 1;
            if (ac < bc)
                return -1;
            else if (ac > bc)
                return 1;
            return sortAlphabetically(a, b, ++index);
        }

        libs.sort(function(a, b){ return sortAlphabetically(a, b); });

        var json =
        '{
          "rebuildStd": $rebuildStd,

          "docStd":
          {
            "title": "Haxe API",
            "xmlPath": "$stdXmlRoot",
            "themePath": "${Path.join([themesRoot, theme])}",
            "outputPath": "$stdOutRoot",
            "readmePath": "",
            "toplevelPackages": [""]
          },
          "docMain":
          {
            "title": "Duell API",
            "xmlPath": "$mainXmlPath",
            "themePath": "${Path.join([themesRoot, theme])}",
            "outputPath": "$mainOutRoot",
            "readmePath": "$readmeRoot",
            "toplevelPackages": ["${libs.join('\", \"')}"]
          }
        }';

        File.saveContent(doxCfgPath, json);
    }

    private function generateReadmeFiles(): Void
    {
        if (!FileSystem.exists(readmeRoot))
            FileSystem.createDirectory(readmeRoot);

        var libs: Array<String> = [for (libDef in PlatformConfiguration.getData().LIBRARIES) libDef.NAME];

        for (lib in libs)
        {
            var fullPath = Path.join([DuellLib.getDuellLib(lib).getPath(), "README.md"]);

            if (!FileSystem.exists(fullPath))
            {
                LogHelper.warn('README.md not found in \"${Path.directory(fullPath)}\"');
                continue;
            }

            File.saveContent(Path.join([readmeRoot, '$lib.md']), File.getContent(fullPath));
        }

        //<-- Uses the duell tool README.md for the home screen -->\\
        var duellPath = Path.join([DuellLib.getDuellLib('duell').getPath(), 'README.md']);
        File.saveContent(Path.join([readmeRoot, 'Home.md']), File.getContent(duellPath));
    }

    private function generateDoxHXML(): Void
    {
        var content = new Array<String>();

        content.push('-cp $generatorRoot');
        content.push('-main DoxRunner');
        content.push('-neko $DOX_N');

        File.saveContent(doxHxmlPath, content.join("\n"));
    }

    public function build(): Void
    {
        var buildPath : String  = hxmlRoot;

        var result = CommandHelper.runHaxe( buildPath,
                                            [BUILD_HXML],
                                            {
                                                logOnlyIfVerbose : false,
                                                systemCommand : true,
                                                errorMessage: "compiling the haxe code",
                                                exitOnError: true
                                            });

        if (result != 0)
        {
            Sys.println('IE/PLATFORM_BUILD: build failed for $BUILD_HXML');
            return;
        }

        runNekoProcess();
    }

    private function runNekoProcess(): Void
    {
        Sys.setCwd(genRoot);
        Sys.command("neko", [doxNPath]);
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