# Duell Build - Documentation
*****************************

## Description

This duell build target creates the documentation for duell libraries.

### How To Use

This generator doesn't autogenerate documenation for every installed library. You have to define some
settings in the used duell_project.xml.

* Add this build target with:

    * `<supported-build-plugin name="documentation" version="master"/>`
    
* Define the to-documenting libraries in the platform-config node with:
    
    * `<library name="duellkit" baseURL="https://api.myhompage.net/"/>`
    
* Define the documentation folder for the library (in duell_library.xml) in the platform-config node with:

    * `<documentation-folder library="polygonal-ds" path="../documentation" pack="de.polygonal.ds"/>`
    
* Build with:
    
    * `duell build documentation -[PLATFORM]`
    * If **no platform** is defined, than the interface classes will be parsed (js is used for the compiler)
     
### Build Flags

You can build the documentation with several flags, for make the process more customized.
The main command is `haxelib run duell_duell build documentation` (short `duell build documentation`) and than you
can add flags like `-[FLAG]`.

* `-android` Generates the documentation for the android/cpp backend
* `-html5` Generates the documentation for the html5 backend
* `-ios` Generates the documentation for the ios/cpp backend
* `-rebuild-std` Forces the generator to rebuild the Haxe API for link correctly to the Haxe API website 
(however, this is forced if the std output folder is empty (OUTPUT_ROOT/generated/dox/std))
* `-xml-only` Generates only a xml file for the defined platform (in the xml output folder)
* `-theme` Build with a custom theme (has to be located in the template folder)
* `-full` Builds the full documentation for all known/supported platforms (merged into one documentation)

## Release Log

### v1.0.0

* Initial release