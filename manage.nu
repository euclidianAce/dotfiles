#!/usr/bin/env nu

def main [] { help main }

let dotfile_dir = $env.DOTFILE_DIR
let save_to = $dotfile_dir | path join .installed.txt

def "main install" [
	--force # Uninstall before installing
	--dry-run # Do not install anything, just print what would be done
	--always-update-installed-list # Always update the installed item list, even with a --dry-run
	other_vars: record = {} # Variables for substitution in locations.txt
] {
	if $force { main uninstall --dry-run=$dry_run }
	let vars = {
		XDG_CONFIG_HOME: ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join .config))
		HOME: $env.HOME
		DOTFILE_DIR: $dotfile_dir
	} | merge $other_vars

	let operations = open ($dotfile_dir | path join locations.tsv) --raw
		| from tsv --comment '#'
		| update Target {|row|
			$row.Target | substitute ($vars | insert Source $row.Source)
		}

	mut targets = []
	for op in $operations {
		try { do-the-thing $op $vars --dry-run=$dry_run } catch {|e|
			print $"Failed to produce ‘($op.Target)’: ($e.msg)"
		}
		$targets = $targets | append $op.Target
	}

	save-installed-locations $targets --dry-run=($dry_run and not $always_update_installed_list)
}

def "main uninstall" [
	--dry-run # Do not uninstall anything, just print what would be done
] {
	load-previous-locations | each { delete $in --dry-run=$dry_run }
	delete $save_to --dry-run=$dry_run
}

# $in: string
def substitute [substitutions: record] -> string {
	iterate --init "" {|src, acc|
		match ($src | parse --regex '(?<head>.*)\$(?<var>\w+)?(?<tail>.*)' | get --ignore-errors 0) {
			null => [null, ($src + $acc)]
			$parsed => (match ($substitutions | get --ignore-errors $parsed.var) {
				null => (error make { msg: $"Variable ‘($parsed.var)’ not found in substitution record: ($substitutions)" })
				$sub => [ $parsed.head, ($sub + $parsed.tail + $acc) ]
			})
		}
	}
}

def do-the-thing [
	row: record<Source: string, Target: string, Via: string>
	vars: record
	--dry-run
] {
	if ($row.Via | str starts-with '^') {
		let subs = $vars
			| insert Source $row.Source
			| insert Target $row.Target
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

# Repeat [src, acc] = fn src acc
# until src is null
def iterate [
	--init: any  # The initial accumulator
	fn: closure  # The closure to iterate
] -> any {
	mut src = $in
	mut acc = $init

	while $src != null {
		let result = do $fn $src $acc
		$src = $result.0
		$acc = $result.1
	}

	$acc
}
