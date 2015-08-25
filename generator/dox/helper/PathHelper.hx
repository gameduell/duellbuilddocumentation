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
import sys.FileSystem;

class PathHelper
{
    static public function getSystemSlashType(): String
    {
       return if (Sys.systemName() == "Windows") "\\" else "/";
    }

    static public function removeBackwardsSigns(str: String): String
    {
        return ~/(\.\.\/)/g.replace(Path.normalize(str), "");
    }

    static public function clearDir(path: String): Void
    {
        try
        {
            if (sys.FileSystem.exists(path))
            {
                PathHelper.removeDirectory(path);
            }
            sys.FileSystem.createDirectory(path);
        }
        catch (e:Dynamic)
        {
            Sys.println('Could not clear directory $path');
            Sys.println(Std.string(e));
            Sys.exit(1);
        }
    }

    static public function removeDirectory(directory : String) : Void
    {
        if (FileSystem.exists(directory))
        {
            var files;
            try
            {
                files = FileSystem.readDirectory(directory);
            }
            catch(e : Dynamic)
            {
                throw "An error occurred while deleting the directory " + directory;
            }

            for (file in FileSystem.readDirectory(directory))
            {
                var path = Path.join([directory, file]);

                try
                {
                    if (FileSystem.isDirectory(path))
                    {
                        removeDirectory(path);
                    }
                    else
                    {
                        try
                        {
                            FileSystem.deleteFile(path);
                        }
                        catch (e:Dynamic)
                        {
                            throw 'An error occurred while deleting the file $path';
                        }
                    }
                }
                catch (e:Dynamic)
                {
                    throw "An error occurred while deleting the directory " + directory;
                }
            }

            try
            {
                FileSystem.deleteDirectory (directory);
            }
            catch (e:Dynamic)
            {
                throw "An error occurred while deleting the directory " + directory;
            }
        }
    }
}