/*Copyright (c) 2003-2015, GameDuell GmbH
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/

package dox.helper;

import haxe.io.Path;
import haxe.io.Path;
import haxe.xml.Fast;
import Xml;
import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class XMLHelper
{
    static public function findXmls(path: String): Map<String, Xml>
    {
        if (!FileSystem.isDirectory(path))
        {
            return [new Path(path).file => parseFile(path)];
        }

        var map: Map<String, Xml> = new Map();

        for (file in FileSystem.readDirectory(path))
        {
            if (!file.endsWith(".xml"))
                continue;

            var p = Path.join([path, file]);

            map[new Path(p).file] = parseFile(p);
        }

        return map;
    }

    static public function parseFile(path: String): Xml
    {
        var name = new Path(path).file;
        var data = File.getContent(path);

        try
        {
            var xml = Xml.parse(data).firstElement();
            return xml;
        }
        catch(e: Dynamic)
        {
            Sys.println('Error while parsing $path');
            return null;
        }
    }
}