package dox;

import haxe.io.Path;
import haxe.Json;
import Map;
import sys.FileSystem;
import sys.io.File;
import templo.Template;

@:keep
class Config {
	public var theme:Theme;
	public var rootPath:String;
	public var homePath:String;
	public var readmePath: String;

	public var toplevelPackage:String;
	public var toplevelPackages:Array<String>;

	public var outputPath(default, set):String;
	public var xmlPath(default, set):String;
	public var pathFilters(default, null):haxe.ds.GenericStack<Filter>;

	public var platforms:Array<String>;
	public var resourcePaths:Array<String>;
	public var templatePaths(default, null):haxe.ds.GenericStack<String>;

	public var defines:Map<String, String>;
	public var pageTitle:String;

	function set_outputPath(v) {
		return outputPath = haxe.io.Path.removeTrailingSlashes(v);
	}

	function set_xmlPath(v) {
		return xmlPath = haxe.io.Path.removeTrailingSlashes(v);
	}

	public function new() {
		theme = null;
		rootPath = "";
		homePath = "";
		readmePath = "";
		toplevelPackage = "";
		toplevelPackages = [];
		outputPath = "";
		xmlPath = "";
		pathFilters = new haxe.ds.GenericStack<Filter>();
		platforms = [];
		resourcePaths = [];
		templatePaths = new haxe.ds.GenericStack<String>();
		defines = new Map();
		pageTitle = "";
	}

	public function addFilter(pattern:String, isIncludeFilter:Bool) {
		pathFilters.add(new Filter(pattern, isIncludeFilter));
	}

	public function removeAllFilter(): Void	{
		pathFilters = new haxe.ds.GenericStack<Filter>();
	}

	public function addTemplatePath(path:String) {
		templatePaths.add(haxe.io.Path.removeTrailingSlashes(path));
	}

	public function loadTemplate(name:String) {
		for (tp in templatePaths)
		{
			if (sys.FileSystem.exists(tp + "/" +name))
			{
				return Template.fromFile(tp + "/" + name);
			}
		}
		throw "Could not resolve template: " +name;
	}

	public function setRootPath(path:String) {
		var depth = path.split(".").length - 1;
		rootPath = "";
		for (i in 0...depth) {
			rootPath += "../";
		}
		if (rootPath == "") rootPath = "./";
	}

	public function getHeaderIncludes() {
		var buf = new StringBuf();
		for (inc in theme.headerIncludes) {
			var path = new haxe.io.Path(inc);
			var s = switch(path.ext) {
				case 'css': '<link href="$rootPath${path.file}.css" rel="stylesheet" />';
				case 'js': '<script type="text/javascript" src="$rootPath${path.file}.js"></script>';
				case 'ico': '<link rel="icon" href="$rootPath${path.file}.ico" type="image/x-icon"></link>';
				case s: throw 'Unknown header include extension: $s';
			}
			buf.add(s);
		}
		return buf.toString();
	}

	public function assignTheme(path: String): Void
	{
		if (path.indexOf("/") == -1 && path.indexOf("\\") == -1)
			path = Path.normalize(Path.join(["themes", path]));

		var configPath = Path.join([path, "config.json"]);
		var themeConfig = File.getContent(configPath);
		var theme:Theme = Json.parse(themeConfig);

		if (theme.parentTheme != null)
			assignTheme(theme.parentTheme);

		resourcePaths.push(Path.join([path, "resources"]));
		assignTemplatePath(Path.join([path, "templates"]));
	}

	public function assignTemplatePath(path: String): Void
	{
		if (FileSystem.exists(path))
			addTemplatePath(path);
		else
			return;

		for (file in FileSystem.readDirectory(path))
		{
			var path = new Path(file);

			if (path.ext == "mtt")
				loadTemplate(file);
		}
	}
}

private class Filter {
	public var r(default, null):EReg;
	public var isIncludeFilter(default, null):Bool;

	public function new(pattern: String, isIncludeFilter:Bool) {
		r = new EReg(pattern, "");
		this.isIncludeFilter = isIncludeFilter;
	}
}
