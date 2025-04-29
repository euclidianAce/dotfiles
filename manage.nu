#!/usr/bin/env nu

use nushell/log.nu

def main []: nothing -> nothing { help main }

def "main help" []: nothing -> nothing { help main }

let dotfile_dir = $env.DOTFILE_DIR
let installed_db = $dotfile_dir | path join .installed.nuon

def "main install" [
	--force (-f) # Uninstall before installing
	--dry-run # Do not install anything, just print what would be done
	--other-vars: record = {} # Variables for substitution in locations.tsv
	...sources # What to install. (Leave empty to install everything)
]: nothing -> nothing {
	if $force { main uninstall --dry-run=$dry_run ...$sources }
	let spec = load-locations-tsv ($dotfile_dir | path join locations.tsv) (substitution-record $other_vars) ...$sources

	let installed: record = $spec
		| reduce --fold {} {|row, acc|
			try {
				do-the-thing $row --dry-run=$dry_run
				$acc | insert $row.Source $row.Target
			} catch {|e|
				log error $"Failed to produce ‘($row.Target)’: ($e.msg)"
				$acc
			}
		}

	let updated = load-installed | merge $installed
	save-installed $updated --dry-run=$dry_run
}

def "main uninstall" [
	--dry-run # Do not uninstall anything, just print what would be done
	...sources # What to uninstall. (Leave empty to uninstall everything)
]: nothing -> nothing {
	let prev = load-installed
	let sources_to_delete: list<string> = if ($sources | length) == 0 {
		$prev | columns
	} else {
		$sources | each {|source|
			let got = $prev | get --ignore-errors $source
			if $got == null { log error $"Unknown source ‘($source)’" }
			$got
		}
	}

	let deleted_sources: list<string> = $sources_to_delete | each {|source|
		let target = $prev | get $source
		try {
			delete $target --dry-run=$dry_run
			$source
		} catch {|e|
			log error $"Failed to delete ‘($target)’: ($e.msg)"
			null
		}
	}

	$prev | reject ...$deleted_sources | save-installed $in --dry-run=$dry_run
}

def "main list-installed" []: nothing -> nothing {
	load-installed
		| items {|key, value| echo $"($key): ($value)" }
		| str join "\n"
		| log info $in
}

def load-locations-tsv [
	from_where: path
	substitutions: record
	...sources
]: nothing -> table<Source: string, Target: string, Via: string> {
	open $from_where --raw
		| from tsv --comment '#'
		| if ($sources | length) == 0 {
			$in
		} else {
			where Source in $sources
		}
		| update Target {|row|
			$row.Target | substitute ($substitutions | insert Source $row.Source)
		}
		| update Via {|row|
			$row.Via | substitute ($substitutions | insert Source $row.Source | insert Target $row.Target)
		}
}

def substitution-record [others: record]: nothing -> record {
	{
		XDG_CONFIG_HOME: ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join .config))
		HOME: $env.HOME
		DOTFILE_DIR: $dotfile_dir
	} | merge $others
}

def substitute [substitutions: record]: string -> string {
	iterate --init "" {|src, acc|
		# TODO: allow $$ as an escape for a single $
		# TODO: should probably use ${foo} or $(foo) or something instead of just $foo
		let parsed = $src | parse --regex '(?<head>.*)\$(?<var>\w+)?(?<tail>.*)' | get --ignore-errors 0
		if $parsed == null { return [null, ($src + $acc)] }
		let sub = $substitutions | get --ignore-errors $parsed.var
		if $sub == null {
			error make {
				msg: $"Variable ‘($parsed.var)’ not found in substitution record: ($substitutions)"
				span: (metadata $substitutions).span
			}
		} else {
			[ $parsed.head, ($sub + $parsed.tail + $acc) ]
		}
	}
}

def do-the-thing [
	row: record<Source: string, Target: string, Via: string>
	--dry-run
] {
	if ($row.Via | str starts-with '^') {
		let cmd_str = $row.Via | str substring 1..
		log info $"Produce ‘($row.Target)’ via external command ‘($cmd_str)’"
		# TODO: if I want windows support, make this cmd.exe I guess?
		if not $dry_run { run-external "/usr/bin/env" "sh" "-c" $cmd_str }
		return
	}
	match $row.Via {
		symlink => { make-link $row.Source $row.Target --dry-run=$dry_run }
		_ => { log error $"Unknown method ‘($row.Via)’" }
	}
}

def make-link [
	dotfile: path
	to_path: path
	--dry-run
] {
	log info $"Link ‘($dotfile)’ to ‘($to_path)’"
	if $dry_run { return }
	^ln --force --no-target-directory --symbolic ($dotfile_dir | path join $dotfile) $to_path
}

def delete [f: path, --dry-run] {
	log info $"Delete ‘($f)’"
	if not $dry_run { rm --recursive --force $f }
}

def save-installed [
	installed: record
	--dry-run
] {
	log info $"Save locations of linked items to ‘($installed_db)’"
	if $dry_run { return }
	$installed
		| to nuon
		| save --force $installed_db
}

def load-installed []: nothing -> record {
	try { open $installed_db --raw | from nuon } catch { {} }
}

# Repeat [src, acc] = fn src acc
# until src is null
def iterate [
	--init: any  # The initial accumulator
	fn: closure  # The closure to iterate
]: any -> any {
	mut src = $in
	mut acc = $init

	while $src != null {
		let result = do $fn $src $acc
		$src = $result.0
		$acc = $result.1
	}

	$acc
}
