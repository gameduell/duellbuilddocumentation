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

import duell.objects.DuellLib;
import haxe.io.Path;
import haxe.xml.Fast;
import sys.FileSystem;

class PlatformXMLParser
{
    public static function parse(data: Fast): Void
    {
        for (element in data.elements)
        {
            switch(element.name)
            {
                case 'documentation':
                    parsePlatform(element);
            }
        }
    }

    public static function parsePlatform(data: Fast): Void
    {
        for (element in data.elements)
        {
            switch(element.name)
            {
                case 'library':
                    parseLibrary(element);
                case 'documentation-folder':
                    parseImportAll(element);
            }
        }
    }

    public static function parseLibrary(data: Fast): Void
    {
        if (!data.has.name || data.att.name == "")
            return;

        if (!data.has.baseURL)
            return;

        PlatformConfiguration.getData().LIBRARIES.push({name: data.att.name, baseURL: data.att.baseURL});
    }

    public static function parseImportAll(data: Fast): Void
    {
        if (!data.has.library || data.att.library == "")
            return;

        if (!data.has.path || data.att.path == "")
            return;

        if (!FileSystem.exists(Path.join([DuellLib.getDuellLib(data.att.library, "master").getPath(), data.att.path])))
            return;

        var pack = if (!data.has.pack) data.att.library else data.att.pack;

        PlatformConfiguration.getData().IMPORTALL.push({library: data.att.library, path: data.att.path, pack: pack});
    }
}
