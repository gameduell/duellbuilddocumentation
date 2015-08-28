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

package duell.helpers;

import duell.build.objects.Configuration;
import duell.build.plugin.platform.PlatformConfiguration;
import String;
import sys.io.FileOutput;
import sys.io.FileInput;
import haxe.xml.Fast;
import haxe.io.Path;
import sys.io.File;
import haxe.xml.Fast;
import sys.FileSystem;
import duell.objects.DuellLib;

typedef ImportAllDefine =
{
    libraryName: String,
    documentationFolder: String,
    importAllPackage: String
}

class ImportHelper
{
    /// Recursive functions

    static public function getImportAllDefinesRecursively(duellLibName: String): Array<ImportAllDefine>
    {
        var documentationLibs: Array<String> = geDocumentationLibsRecursively(duellLibName);
        var dependencyLibs: Array<String> = getDependencyLibsRecursively(duellLibName);

        for (lib in documentationLibs)
        {
            dependencyLibs = concatWithoutDuplication(dependencyLibs, getDependencyLibsRecursively(lib));
        }

        var allLibs: Array<String> = [duellLibName];
        allLibs = concatWithoutDuplication(allLibs, documentationLibs);
        allLibs = concatWithoutDuplication(allLibs, dependencyLibs);

        var importAllDefines: Array<ImportAllDefine> = [];

        for (lib in allLibs)
        {
            importAllDefines.push(getImportAllDefine(lib));
        }

        return importAllDefines;
    }

    static private function geDocumentationLibsRecursively(duellLibName: String): Array<String>
    {
        var openLibs: Array<String> = getDocumentationLibs(duellLibName);
        var dependencies: Array<String> = [];

        while(openLibs.length > 0)
        {
            if (dependencies.indexOf(openLibs[0]) < 0)
            {
                dependencies.push(openLibs[0]);
                var depsOfDeps = getDocumentationLibs(openLibs[0]);
                openLibs = openLibs.concat(depsOfDeps);
            }
            openLibs.shift();
        }

        return dependencies;
    }

    static private function getDependencyLibsRecursively(duellLibName: String): Array<String>
    {
        var openLibs: Array<String> = getDependencyLibs(duellLibName);
        var dependencies: Array<String> = [];

        while(openLibs.length > 0)
        {
            if (dependencies.indexOf(openLibs[0]) < 0)
            {
                dependencies.push(openLibs[0]);
                var depsOfDeps = getDependencyLibs(openLibs[0]);
                openLibs = openLibs.concat(depsOfDeps);
            }
            openLibs.shift();
        }

        return dependencies;
    }

    /// Single task functions

    static private function getImportAllDefine(duellLibName: String): ImportAllDefine
    {
        for (importAll in PlatformConfiguration.getData().IMPORTALL)
        {
            if (importAll.library != duellLibName)
            {
                continue;
            }

            var pack: String = if (importAll.pack != "") importAll.pack else duellLibName;

            var root: String = Path.join([DuellLib.getDuellLib(importAll.library, "master").getPath(), importAll.path]);
            var docuExt: String = Path.join(pack.split('.'));

            if (!FileSystem.exists(Path.join([root, docuExt, 'ImportAll.hx'])))
            {
                trace(Path.join([root, docuExt, 'ImportAll.hx']));
                break;
            }

            return {libraryName : duellLibName, documentationFolder : root, importAllPackage : pack};
        }

        var pack = duellLibName;

        var defaultRoot: String = Path.join([DuellLib.getDuellLib(duellLibName, "master").getPath(), "documentation"]);
        var defaultDocuExt: String = Path.join(pack.split('.'));

        if (FileSystem.exists(Path.join([defaultRoot, defaultDocuExt, "ImportAll.hx"])))
        {
            var content: String = File.getContent(Path.join([defaultRoot, defaultDocuExt, "ImportAll.hx"]));

            if (content.length != 0 && content.indexOf("import") != -1)
            {
                return {libraryName : duellLibName, documentationFolder : defaultRoot, importAllPackage : pack};
            }
        }

        var exportRoot: String = Path.join([Configuration.getData().OUTPUT, "documentation", "generated", "documentation"]);

        LogHelper.warn('Missing ImportAll file for $duellLibName, temporarly generated into $exportRoot');

        createImportAllFile(duellLibName, exportRoot, pack.split('.').join('/')); // TODO Probably not working with windows

        return {libraryName : duellLibName, documentationFolder : exportRoot, importAllPackage : pack};
    }

    static private function getDocumentationLibs(duellLibName: String): Array<String>
    {
        var documentationLibs: Array<String> = [];
        var path: String = DuellLib.getDuellLib(duellLibName).getPath();

        if (FileSystem.readDirectory(path).indexOf("duell_library.xml") < 0)
        {
            return documentationLibs; // no duell_library.xml found
        }

        var xmlFast: Fast = new Fast(Xml.parse(File.getContent(Path.join([path, "duell_library.xml"]))).firstElement());

        if (!xmlFast.hasNode.resolve('platform-config'))
        {
            return documentationLibs; // no platform-config tag found
        }

        var platformConfigNode: Fast = xmlFast.node.resolve('platform-config');

        if (!platformConfigNode.hasNode.documentation)
        {
            return documentationLibs; // no documentation tag in platform-config tag found
        }

        var documentationNode: Fast = platformConfigNode.node.documentation;

        for (library in documentationNode.nodes.library)
        {
            if (!library.has.name)
            {
                continue; // Invalid duelllib definition in documentation tag
            }

            documentationLibs.push(library.att.name);
        }

        return documentationLibs;
    }

    static private function getDependencyLibs(duellLibName: String): Array<String>
    {
        var dependencyLibs: Array<String> = [];
        var path: String = DuellLib.getDuellLib(duellLibName).getPath();

        if (FileSystem.readDirectory(path).indexOf("duell_library.xml") < 0)
        {
            return dependencyLibs; // no duell_library.xml found
        }

        var xmlFast: Fast = new Fast(Xml.parse(File.getContent(Path.join([path, "duell_library.xml"]))).firstElement());

        for (duelllib in xmlFast.nodes.duelllib)
        {
            if (!duelllib.has.name || !duelllib.has.version)
            {
                continue; // Invalid duelllib definition
            }

            dependencyLibs.push(duelllib.att.name);
        }

        return dependencyLibs;
    }

    /// ImportAll file helper

    static private function createImportAllFile(duellLibName: String, root: String, importAllPath: String): String
    {
        var importAllDirectory: String = Path.join([root, importAllPath]);
        var libImports: Array<String> = getImportsFromLib(duellLibName);
        var importAllContent: String = "package " + pathToPackage(importAllPath) + ";\n";

        for (libImport in libImports)
        {
            importAllContent += 'import $libImport;\n';
        }

        if (!FileSystem.exists(importAllDirectory))
        {
            FileSystem.createDirectory(importAllDirectory);
        }

        var importAllFilePath: String = Path.join([importAllDirectory, 'ImportAll.hx']);

        File.saveContent(importAllFilePath, importAllContent);

        return importAllFilePath;
    }

    static private function getImportsFromLib(duellLibName: String): Array<String>
    {
        var libPath: String = DuellLib.getDuellLib(duellLibName).getPath();
        var source: String = Path.join([libPath, duellLibName]);
        var imports: Array<String> = [];

        if (!FileSystem.exists(source))
        {
            return imports; // There is no interface folder (interface folder name should be like lib name)
        }

        var mainPackage: String = Path.withoutDirectory(source);
        var unknownContent: Array<String> = getContentOfDir(source);

        while (unknownContent.length > 0)
        {
            var contentPath: String = unknownContent[0];
            unknownContent.shift();

            if (FileSystem.isDirectory(contentPath))
            {
                unknownContent = unknownContent.concat(getContentOfDir(contentPath));
                continue; // CurrentContent is a directory
            }

            if (contentPath.lastIndexOf(".hx") < 0)
            {
                continue; // CurrentContent is not a haxe file
            }

            imports.push(getPackageOfPath(contentPath, mainPackage));
        }

        return imports;
    }

    /// Path helper

    static private function getPackageOfPath(path: String, mainPackage: String): String
    {
        var packagePath: String = path.substring(path.indexOf(mainPackage) + mainPackage.length + 1, path.length - 3);

        return pathToPackage(packagePath);
    }

    static private function pathToPackage(path: String): String
    {
        if (path == null || path == "")
        {
            return "";
        }

        var delimiter: String = Path.addTrailingSlash(path).substr(path.length);
        var singlePackages: Array<String> = path.split(delimiter);

        var packagePath: String = singlePackages.shift();

        for (subPackage in singlePackages)
        {
            packagePath += '.$subPackage';
        }

        return packagePath;
    }

    static private function getContentOfDir(source: String): Array<String>
    {
        var folderContent: Array<String> = FileSystem.readDirectory(source);

        for (i in 0 ... folderContent.length)
        {
            folderContent[i] = Path.join([source, folderContent[i]]);
        }

        return folderContent;
    }

    /// Array helper

    static public function concatWithoutDuplication(a: Array<String>, b: Array<String>): Array<String>
    {
        for (str in b)
        {
            if (a.indexOf(str) < 0)
            {
                a.push(str);
            }
        }

        return a;
    }
}