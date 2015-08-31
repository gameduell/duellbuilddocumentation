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
import duell.build.plugin.platform.PlatformConfiguration.ImportAllDefine;
import duell.objects.DuellLib;
import haxe.io.Path;
import haxe.xml.Fast;
import sys.FileSystem;
import sys.io.File;

class ImportAllHelper
{
    inline static private var LIBRARY_XML: String = "duell_library.xml";

    inline static private var EXP_DIR: String = "documentation";    // -Located in export root
    inline static private var GEN_DIR: String = "generated";        // --Located in docRoot
    inline static private var DOC_DIR: String = "documentation";    // ---Located in genRoot

    static public function getImportAllDefines(lib: String): Array<ImportAllDefine>
    {
        var dependencies = getDependenciesRecursive(lib);
        dependencies.push(lib);

        return [for (dep in dependencies) getImportAllDefine(dep)];
    }

    static private function getDependenciesRecursive(lib: String): Array<String>
    {
        var open = getDependencies(lib);
        var closed = [];

        while (open.length > 0)
        {
            closed.push(open.shift());
            open = open.concat(getDependencies(closed[closed.length - 1]).filter(function(s) {
                if (closed.indexOf(s) == -1 && open.indexOf(s) == -1)
                    return true;
                return false;
            }));
        }

        return closed;
    }

    static private function getDependencies(lib: String): Array<String>
    {
        var fullPath: String = Path.join([DuellLib.getDuellLib(lib).getPath(), LIBRARY_XML]);

        if (!FileSystem.exists(fullPath))
            return [];

        var fast = new Fast(Xml.parse(File.getContent(fullPath)).firstElement());

        return getDocDependencies(fast).concat(getLibDependencies(fast));
    }

    static private function getDocDependencies(fast: Fast): Array<String>
    {
        if (!fast.hasNode.resolve('platform-config'))
            return [];

        if (!fast.node.resolve('platform-config').hasNode.documentation)
            return [];

        var docNode = fast.node.resolve('platform-config').node.documentation;

        return [for (lib in docNode.nodes.library) if (lib.has.name) lib.att.name];
    }

    static private function getLibDependencies(fast: Fast): Array<String>
    {
        return [for (lib in fast.nodes.duelllib) if (lib.has.name) lib.att.name];
    }

    static public function getImportAllDefine(lib: String): ImportAllDefine
    {
        var compare = PlatformConfiguration.getData().IMPORTALL.filter(function(t) {
           if (t.LIB == lib)
               return true;
            return false;
        });

        if (compare.length == 1)
            return compare.shift();

        var docRoot = Path.join([DuellLib.getDuellLib(lib).getPath(), DOC_DIR]);

        if (FileSystem.exists(Path.join([docRoot, lib])))
            return {LIB: lib, DOC_ROOT: docRoot, DOC_PACKAGE: lib};

        docRoot = Path.join([Configuration.getData().OUTPUT, EXP_DIR, GEN_DIR, DOC_DIR]);
        createImportAllFile(lib, docRoot);

        LogHelper.warn('Missing ImportAll file for \"$lib\", temporarly generated into \"$docRoot\"');

        return {LIB: lib, DOC_ROOT: docRoot, DOC_PACKAGE: lib};
    }

    static private function createImportAllFile(lib: String, docRoot: String): Void
    {
        var root = Path.join([docRoot, lib]);
        var libImports = getImports(lib);

        var importContent = [for (i in libImports) 'import $i;'].join('\n');
        var fullContent = 'package $lib;\n$importContent';

        if (!FileSystem.exists(root))
            FileSystem.createDirectory(root);

        File.saveContent(Path.join([root, 'ImportAll.hx']), fullContent);
    }

    static private function getImports(lib: String): Array<String>
    {
        var source: String = Path.join([DuellLib.getDuellLib(lib).getPath(), lib]);

        if (!FileSystem.exists(source))
            return [];

        var open = FileSystem.readDirectory(source);
        var closed = [];

        while (open.length > 0)
        {
            var basePath = open.shift();
            var fullPath = Path.join([source, basePath]);

            if (FileSystem.isDirectory(fullPath))
            {
                open = open.concat([for (c in FileSystem.readDirectory(fullPath)) Path.join([basePath, c])]);
                continue;
            }

            if (Path.extension(fullPath) != 'hx')
                continue;

            var filePath = Path.withoutExtension(Path.join([lib, basePath]));
            var slashType = Path.addTrailingSlash(filePath).substr(filePath.length);

            closed.push(filePath.split(slashType).join('.'));
        }

        return closed;
    }
}