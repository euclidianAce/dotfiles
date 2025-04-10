#!/usr/bin/env nu

def main [] { help main }

let xdg_config_home = $env.XDG_CONFIG_HOME? | default ($env.HOME | path join .config)
let dotfile_dir = $env.DOTFILE_DIR
let vars = [
	[name, replacement];
	["XDG_CONFIG_HOME", $xdg_config_home]
	["HOME", $env.HOME]
	["DOTFILE_DIR", $dotfile_dir]
]
let save_to = $dotfile_dir | path join .installed.txt

def "main install" [
	--force # Uninstall before installing
	--dry-run # Do not install anything, just print what would be done
	--always-update-installed-list # Always update the installed item list, even with a --dry-run
] {
	if $force { main uninstall }
	open ($env.DOTFILE_DIR | path join locations.tsv)
		| update Target {|row|
			$row.Target | substitute ($vars | append {name:Source, replacement:$row.Source})
		}
		| each {
			let row = $in
			try { do-the-thing $row --dry-run=$dry_run } catch {|e|
				print $"Failed to produce ‘($row.Target)’: ($e.msg)"
			}
			$row.Target
		}
		| save-installed-locations $in --dry-run=($dry_run and not $always_update_installed_list)
}

def "main uninstall" [
	--dry-run # Do not uninstall anything, just print what would be done
] {
	load-previous-locations | each { delete $in --dry-run=$dry_run }
	delete $save_to --dry-run=$dry_run
}

# $in: string
def substitute [substitutions: table<name: string, replacement: string>] -> string {
	let src = $in
	$substitutions | reduce --fold $src {|it, acc|
		$acc | str replace --all ("$" + $it.name) $it.replacement
	}
}

def do-the-thing [
	row: record<Source: string, Target: string, Via: string>
	--dry-run
] {
	if ($row.Via | str starts-with '^') {
		let subs = $vars
			| append {name:Source, replacement:$row.Source}
			| append {name:Target, replacement:$row.Target}
		let cmd_str = $row.Via
			| str substring 1..
			| substitute $subs
		print $"Produce ‘($row.Target)’ via external command ‘($cmd_str)’"
		# TODO: if I want windows support, make this cmd.exe I guess?
		if not $dry_run { run-external "/usr/bin/env" "sh" "-c" $cmd_str }
		return
	}
	match $row.Via {
		symlink => { make-link $row.Source $row.Target --dry-run=$dry_run }
		_ => { print $"Unknown method ‘($row.Via)’" }
	}
}

def make-link [
	dotfile: path
	to_path: path
	--dry-run (-d)
] {
	print $"Link ‘($dotfile)’ to ‘($to_path)’"
	if not $dry_run {
		^ln -T -s ($dotfile_dir | path join $dotfile) $to_path
	}
}

def delete [f: path, --dry-run] {
	print $"Delete ‘($f)’"
	if not $dry_run { rm --recursive --force $f }
}

def save-installed-locations [locations: list<string>, --dry-run] {
	print $"Save locations of linked items to ($save_to)"
	if not $dry_run { $locations | save --force $save_to }
}

def load-previous-locations [] -> list<string> {
	let opened = try { open $save_to } catch { "" }
	$opened | lines
}
