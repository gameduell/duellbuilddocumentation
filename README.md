# GameDuell Haxe Documentation Generator

## Description

This duell build target creates the documentation for duell libraries.

## How To Use

This generator doesn't autogenerate documenation for every installed library. You have to define some
settings in the used duell_project.xml.

* Add this build target with:

    * `<supported-build-plugin name="unitylayout" version="4.0.0+"/>`
    
* Define the to documenting libraries in the platlform-config node with:
    
    * `<supported-build-plugin name="unitylayout" version="4.0.0+"/>`
    
* Build with:
    
    * `duell build documentation`
    * Flags:
       
        * -rebuildStd: Flags the generator to rebuild the Haxe API for linking correctly external (however, this is forced if it doesn't exists)
        * -theme: Build with a custom theme (located in the template folder)

## Release Log

### v1.0.0

* Initial release