# Duell Build - Documentation

## Description

This duell build target creates the documentation for duell libraries.

## How To Use

This generator doesn't autogenerate documenation for every installed library. You have to define some
settings in the used duell_project.xml.

* Add this build target with:

    * `<supported-build-plugin name="documentation" version="master"/>`
    
* Define the to-documenting libraries in the platform-config node with:
    
    * `<library name="gdkit" baseURL="https://api.myhompage.net/"/>`
    
* Build with:
    
    * `duell build documentation`
    * Flags:
       
        * `-rebuildStd` Forces the generator to rebuild the Haxe API for link correctly to the Haxe API website (however, this is forced if it doesn't exists)
        * `-theme` Build with a custom theme (located in the template folder)

## Release Log

### v1.0.0

* Initial release