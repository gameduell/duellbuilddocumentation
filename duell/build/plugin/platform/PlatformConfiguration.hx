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
import duell.helpers.LogHelper;
typedef PlatformConfigurationData = {
    PLATFORM_NAME: String,
    LIBRARIES: Array<{name : String, baseURL: String}>,
    IMPORTALL: Array<{library: String, path: String}>,
    IMPORTS: String
}

class PlatformConfiguration
{
    private static var configuration: PlatformConfigurationData = null;
    private static var parsingDefines: Array<String> = [];

    public static function getData(): PlatformConfigurationData
    {
        if (configuration == null)
        {
            initConfig();
        }

        return configuration;
    }

    public static function getConfigParsingDefines(): Array<String>
    {
        return parsingDefines;
    }

    public static function addParsingDefine(define: String): Void
    {
        if (parsingDefines.indexOf(define) < 0)
        {
            parsingDefines.push(define);
        }
        else
        {
            LogHelper.warn('Parsing define "$define" is already set"');
        }
    }

    private static function initConfig(): Void
    {
        configuration =
        {
            PLATFORM_NAME : "documentation",
            LIBRARIES : [],
            IMPORTALL : [],
            IMPORTS : "package;\n"
        };
    }
}
