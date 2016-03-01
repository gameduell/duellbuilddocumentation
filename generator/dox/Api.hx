package dox;

import haxe.Json;
import dox.helper.PathHelper;
import haxe.rtti.CType;
import sys.FileSystem;

using Lambda;
using StringTools;

/**
	Additional information on class fields
**/
typedef FieldInfo =
{
	/**
		The kind of the field. See `FieldKind`.
	**/
    kind: FieldKind,

	/**
		The field modifiers. See `FieldModifiers`.
	**/
    modifiers: FieldModifiers
}

/**
	Describes the kind of a class field.
**/
enum FieldKind {
	/**
		Field is a variable. Properties with `default, default` access are
		also considered variables.
	**/
	Variable;
	/**
		Field is a property. The arguments `get` and `set` correspond to the
		accessor.
	**/
	Property(get: String, set: String);
	/**
		Field is a method with arguments `args` and return type `ret`.
	**/
	Method(args: List<FunctionArgument>, ret: CType);
}

/**
	The modifiers of a field.
**/
typedef FieldModifiers =
{
	/**
		`true` if the field is `inline`, `false` otherwise
	**/
	isInline: Bool,
	/**
		`true` if the field is `dynamic`, `false` otherwise
	**/
	isDynamic: Bool,
}

typedef MemberField =
{
	field: ClassField,
	definedBy: Classdef
}

/**
	The Api class is the general interface to the Dox system which can be
	accessed in templates from the global `api` instance.
**/
@:keep
class Api {

	inline static private var HAXE_API: String = "http://api.haxe.org/";

	/**
		The Dox configuration, see `Config` for details.
	**/
	public var config:Config;

	/**
		This instance of `Infos` contains various information which is collected
		by the Dox processor.
	**/
	public var infos:Infos;

	/**
		The current page name. For types this is the type name, for packages it
		is `"package "` followed by the package name.
	**/
	public var currentPageName:String;

	public function new(cfg:Config, infos:Infos) {
		this.config = cfg;
		this.infos = infos;
	}

	/**
		Checks if `name` is a known platform name.

		Platform names correspond to the filenames of the consumed .xml files.
		For instance, flash.xml defines target "flash".
	**/
	public function isPlatform(name:String):Bool
	{
		return config.platforms.has(name);
	}

	/**
		Returns the name of `tree`, which is the unqualified name of the
		package of type represented by `tree`.
	**/
	public function getTreeName(tree:TypeTree):String {
		return switch(tree) {
			case TPackage(name,_,_): name;
			case TClassdecl(t): getPathName(t.path);
			case TEnumdecl(t): getPathName(t.path);
			case TTypedecl(t): getPathName(t.path);
			case TAbstractdecl(t): getPathName(t.path);
		}
	}

	/**
		Returns the full dot-path of `tree`.
	**/
	public function getTreePath(tree:TypeTree):String {
		return switch(tree) {
			case TPackage(_,path,_): path;
			case TClassdecl(t): t.path;
			case TEnumdecl(t): t.path;
			case TTypedecl(t): t.path;
			case TAbstractdecl(t): t.path;
		}
	}

	/**
		Returns the package of `tree`, which is the dot-path without the type
		name for types and the package itself for packages.
	**/
	public function getTreePack(tree:TypeTree):String {
		return switch(tree) {
			case TPackage(_,pack,_): pack;
			case TClassdecl(t): getPathPack(t.path);
			case TEnumdecl(t): getPathPack(t.path);
			case TTypedecl(t): getPathPack(t.path);
			case TAbstractdecl(t): getPathPack(t.path);
		}
	}

	/**
		Returns the URL of `tree`, following the conventions of Dox.

		For packages, the returned value is the slash-path of the package
		followed by "/index.html".

		For types, `pathToUrl` is called with the type path.
	**/
	public function getTreeUrl(tree:TypeTree):String {
		return switch(tree) {
			case TPackage(_, full, _): config.rootPath + full.split(".").join("/") + "/index.html";
			case TClassdecl(t): pathToUrl(t.path);
			case TEnumdecl(t): pathToUrl(t.path);
			case TTypedecl(t): pathToUrl(t.path);
			case TAbstractdecl(t): pathToUrl(t.path);
		}
	}

	/**
		Returns the short description of `tree`.

		@todo: Document this properly.
	**/
	public function getTreeShortDesc(tree:TypeTree):String {
		var infos:TypeInfos = switch(tree) {
			case TPackage(_, full, _): null;
			case TClassdecl(t): t;
			case TEnumdecl(t): t;
			case TTypedecl(t): t;
			case TAbstractdecl(t): t;
		}
		return getShortDesc(infos);
	}

	/**
		Returns the short description of `infos`.

		@todo: Document this properly.
	**/
	public function getShortDesc(infos:TypeInfos):String {
		return infos == null ? "" : infos.doc.substr(0, infos.doc.indexOf('</p>') + 4);
	}

	/**
		Returns the first sentence of the documentation belonging to `infos`.
	**/
	public function getSentenceDesc(infos:TypeInfos):String {
		if (infos == null) {
			return "";
		}
		var stripped = ~/<.+?>/.replace(infos.doc, "").replace("\n", " ");
		var sentence = ~/^(.*?[.?!]+)/;
		return sentence.match(stripped) ? sentence.matched(1) : "";
	}

	public function getMainPackage(path:Path): String {
		return path.split(".")[0];
	}

	/**
	    Turns a dot path (package path) into a normal system path with the system specific slash type
	**/
	public function packagePathToPath(path:Path): String {
		return path.split(".").join(PathHelper.getSystemSlashType());
	}

	/**
		Turns a dot-path into a slash-path and appends ".html".
	**/
	public function pathToUrl(path:Path):String {
		return config.rootPath + path.split(".").join("/") + ".html";
	}

	public function pathToStdURL(path:Path): String {
		return HAXE_API + PathHelper.removeBackwardsSigns(pathToUrl(path));
	}

	public function pathToDuelllib(path:Path): String {
		var libPath: String = haxe.io.Path.join([getMainPackage(path), PathHelper.removeBackwardsSigns(pathToUrl(path))]);
		return config.homePath + config.rootPath + libPath;
	}

	/**
		Checks if `path` corresponds to a known type.
	**/
	public function isKnownType(path:Path):Bool {
		return infos.typeMap.exists(path);
	}

	/**
		Checks if `path` corresponds to a Haxe Std type.
	**/
	public function isStdType(path:Path): Bool {
		if (!config.defines.exists(DoxRunner.DEF_STD_ROOT))
			return false;
		var stdFile: String = PathHelper.removeBackwardsSigns(pathToUrl(path));
		var stdRoot: String = config.defines.get(DoxRunner.DEF_STD_ROOT);
		return FileSystem.exists(haxe.io.Path.join([stdRoot, stdFile]));
	}

	/**
		Checks if `path` corresponds to a duell lib type.
	**/
	public function isDuelllibType(path:Path): Bool {
		return true; // TODO Currently everything unknown is linked as DuellLib
	}

	/**
		Resolves a type by its dot-path `path`.
	**/
	public function resolveType(path:Path):Null<TypeInfos> {
		return infos.typeMap.get(path);
	}

	/**
		Returns the dot-path of type `ctype`.

		If `ctype` does not have a real path, `null` is returned.
	**/
	public function getTypePath(ctype:CType):Null<String> {
		return switch (ctype) {
			case CClass(path,_): path;
			case CEnum(path, _): path;
			case CTypedef(path, _): path;
			case CAbstract(path, _): path;
			case _: null;
		}
	}

	/**
		Returns the last part of dot-path `path`.
	**/
	public function getPathName(path:Path):String {
		return path.split(".").pop();
	}

	/**
		Returns the package part of dot-path `path`.

		If `path` does not have a package, the empty string `""` is returned.
	**/
	public function getPathPack(path:Path):String {
		var parts = path.split(".");
		parts.pop();
		return parts.length == 0 ? "" : parts.join(".") + ".";
	}

	/**
		Traces `e` for debug purposes.
	**/
	public function debug(e:Dynamic):Void {
		trace(Std.string(e));
	}

	/**
		Traces `e` as pretty-printed Json for debug purposes.
	**/
	public function debugJson(e:Dynamic) {
		trace(Json.stringify(e, null, "  "));
	}

	/**
		Checks if `field` is an abstract implementation field.

		Abstract implementation fields are abstract fields which are not static
		in the original definition.
	**/
	public function isAbstractImplementationField(field:ClassField):Bool {
		return field.meta.exists(function(m) return m.name == ":impl");
	}

	/**
		Returns the CSS class string corresponding to `platforms`. If
		`platforms is empty, `null` is returned.
	**/
	public function getPlatformClassString(platforms:List<String>):String {
		if (platforms.isEmpty()) return null;
		return "platform " + platforms.map(function(p){ return "platform-"+p; }).join(" ");
	}

	/**
		Checks if `key` was defined from command line argument `-D key value`.
	**/
	public function isDefined(key:String):Bool {
		return config.defines.exists(key);
	}

	/**
		Returns the value of `key` as defined by command line argument
		`-D key value`. If no value is defined, null is returned.
	**/
	public function getValue(key:String):Null<String> {
		return config.defines[key];
	}

	/**
		Returns the path to the source code of `type`. This method assumes that
		`source-path` was defined from command line (`-D source-path url`) and
		then appends the path of `type` to it.
	**/
	public function getSourceLink(type:TypeInfos) {
		var module = type.module != null ? type.module : type.path;
		return haxe.io.Path.join([getValue("source-path"), module.replace(".", "/") + ".hx"]);
	}

	/**
		Returns additional field information which is not available on the
		`ClassField` type. See `FieldInfo` for more information.
	**/
	public function getFieldInfo(cf:ClassField):FieldInfo {
		var modifiers = {
			isInline: false,
			isDynamic: false
		}
		var isMethod = false;
		var get = "default";
		var set = "default";
		switch (cf.set) {
			case RNo:
				set = "null";
			case RCall(_):
				set = "set";
			case RMethod:
				isMethod = true;
			case RDynamic:
				set = "dynamic";
				isMethod = true;
				modifiers.isDynamic = true;
			default:
		}
		switch (cf.get) {
			case RNo:
				get = "null";
			case RCall(_):
				get = "get";
			case RDynamic:
				get = "dynamic";
			case RInline:
				modifiers.isInline = true;
			default:
		}
		function varOrProperty() {
			return if (get == "default" && set == "default") {
				Variable;
			} else {
				Property(get, set);
			}
		}
		var kind = if (isMethod || modifiers.isInline) {
			switch (cf.type) {
				case CFunction(args, ret):
					Method(args, ret);
				default:
					varOrProperty();
			}
		} else {
			varOrProperty();
		}
		return {
			kind: kind,
			modifiers: modifiers
		}
	}

	/**
		Checks whether `cf` is a method using `getFieldInfo()`.
	**/
	public function isMethod(cf:ClassField) {
		return getFieldInfo(cf).kind.match(Method(_, _));
	}

	/**
		Returns an array of all member fields of `c` respecting the inheritance
		chain.
	**/
	public function getAllFields(c:Classdef):Array<MemberField> {
		var allFields = [];
		var fieldMap = new Map();
		function loop(c:Classdef) {
			for (cf in c.fields) {
				if (!fieldMap.exists(cf.name) || cf.overloads != null) {
					allFields.push({ field: cf, definedBy: c});
					fieldMap[cf.name] = true;
				}
			}
			if (c.superClass != null) {
				var cSuper:Classdef = cast infos.typeMap[c.superClass.path];
				if (cSuper != null) { // class is not part of documentation
					loop(cSuper);
				}
			}
		}
		loop(c);
		allFields.sort(function(f1, f2) return Reflect.compare(f1.field.name, f2.field.name));
		return allFields;
	}

	/**
		Checks if `subs` only contains one library define.
	**/
	public function isSingleLib(subs: Array<String>): Bool {
		return subs.length == 1;
	}

	/**
		Checks if `lib` has an existing markdown readme file.
	**/
	public function hasReadMe(lib: String): Bool {
		return FileSystem.exists(haxe.io.Path.join([config.readmePath, '$lib.md']));
	}

	/**
		Returns the content of the markdown readme file for `lib`.
		The returned content is preformated by the markdown library and some internal functions.
	**/
	public function getReadMe(lib: String): String {
		var docStateBadge = getStateBadge();
		var readmeContent = sys.io.File.getContent(haxe.io.Path.join([config.readmePath, '$lib.md']));
		return Markdown.markdownToHtml('$docStateBadge\n\n$readmeContent');
	}

	/**
		Create a badge link with the number for the documentation process in percent.
	**/
	public function getStateBadge(): String {
		if (infos == null)
			return '';
		return '![DOC_STATE](https://img.shields.io/badge/Documented-${infos.getDocPercentage()}%25-blue.svg)';
	}

	/**
		Checks if the current Package is stacked (e.g. ds.polygonal.ds)
	**/
	public function isStackedPackage(tree: TypeTree): Bool {
		return getStackedPackage(tree).split(".").length > 1;
	}

	/**
		Creates a combined name for stacked packages (e.g. ds/polygonal/ds/[FILE] -> ds.polygonal.ds/[File])
	**/
	public function getStackedPackage(tree: TypeTree): String {
		switch(tree) {
			case TPackage(name, full, subs):
				if (subs.length == 1) {
					var p = getStackedPackage(subs[0]);
					if (p != "")
						return '$name.$p';
				}
				return name;
			default: return "";
		}
	}

	/**
		Returns the TypeTree's for the defined package.
		Attention: This function is only mentiond for use in combination with isStackedPackage and getStackedPackage!
	**/
	public function getTreesForStackedPackage(tree: TypeTree, pack: String): Array<TypeTree> {
		var split = pack.split('.');
		switch(tree) {
			case TPackage(name, full, subs):
				if (name == split[split.length - 1]) {
					return subs;
				}
				return getTreesForStackedPackage(subs[0], pack);
			default: return null;
		}
	}

	/**
	* Flags the platform drop down menu as enabled or not.
	* TODO Works only, if platform is defined as package, otherwise everything will be displayed!
	* @param return Bool for disabled/enabled platform drop down menu
	* **/
	public function platformDropDownEnabled(): Bool {
		return config.docPackages.length == 0;
	}

	/**
	* Takes the current Date and returns the year
	* @return Year as Int in format ####
	* **/
	public function getYear(): Int {
		return Date.now().getFullYear();
	}
}