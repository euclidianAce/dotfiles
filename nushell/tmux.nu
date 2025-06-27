use std

export def command [...arguments] {
	^tmux ...$arguments
}

export def list-sessions [
	--activity             # Time of session last activity
	--alerts               # List of window indexes with alerts
	--attached             # Number of clients session is attached to
	--attached-list        # List of clients session is attached to
	--created              # Time session created
	--format               # True if format is for a session
	--group                # Name of session group
	--group-attached       # Number of clients sessions in group are attached to
	--group-attached-list  # List of clients sessions in group are attached to
	--group-list           # List of sessions in group
	--group-many-attached  # True if multiple clients attached to sessions in group
	--group-size           # Size of session group
	--grouped              # True if session in a group
	--id                   # Unique session ID
	--last-attached        # Time session last attached
	--many-attached        # True if multiple clients attached
	--marked               # True if this session contains the marked pane
	--name                 # Session name
	--path                 # Working directory of session
	--stack                # Window indexes in most recent order
	--windows              # Number of windows in session
]: nothing -> table {
	let transform = [[name,include,tag,list_item];
		[ 'activity',             $activity,            "time",   null ]
		[ 'alerts',               $alerts,              "list",   "int" ]
		[ 'attached',             $attached,            "bool",   null ]
		[ 'attached_list',        $attached_list,       "list",   null ]
		[ 'created',              $created,             "time",   null ]
		[ 'format',               $format,              "bool",   null ]
		[ 'group',                $group,               "str",    null ]
		[ 'group_attached',       $group_attached,      "int",    null ]
		[ 'group_attached_list',  $group_attached_list, "list",   null ]
		[ 'group_list',           $group_list,          "list",   null ]
		[ 'group_many_attached',  $group_many_attached, "bool",   null ]
		[ 'group_size',           $group_size,          "int",    null ]
		[ 'grouped',              $grouped,             "bool",   null ]
		[ 'id',                   $id,                  "str",    null ]
		[ 'last_attached',        $last_attached,       "time",   null ]
		[ 'many_attached',        $many_attached,       "bool",   null ]
		[ 'marked',               $marked,              "bool",   null ]
		[ 'name',                 $name,                "str",    null ]
		[ 'path',                 $path,                "str",    null ]
		[ 'stack',                $stack,               "list",   "int" ]
		[ 'windows',              $windows,             "int",    null ]
	]

	let all = not ($transform.include | any { $in })
	let transform = $transform
		| if $all { $in } else { where include }

	let names_and_format = $transform
		| reduce --fold [] {|it, acc|
			$acc | append {name: $it.name, format: ('#{session_' + $it.name + '}')}
		}

	let format_string = $names_and_format | get format | str join ';'

	let data = (^tmux list-sessions -F $format_string e> (std null-device))
		| from csv --noheaders --separator ';' --no-infer
		| rename ...$names_and_format.name

	$transform | reduce --fold $data {|tf, acc|
		update $tf.name {|it|
			let cell = $it | get $tf.name
			if $cell == "" or $cell == null { return null }
			$cell | convert $tf.tag ($tf.list_item | default "string")
		}
	}
}

export alias ls = list-sessions

def convert [tname: string, list_item: string]: any -> any {
	match $tname {
		"bool" => { into bool }
		"int" => { into int }
		"time" => { into int | $in * 1_000_000_000 | into datetime }
		"str" => { into string }
		"list" => {
			split row ','
			| where ($it | str length) > 0
			| each { convert ($list_item | default "string") "string" }
		}
	}
}

export def new-or-attach [] {
	let unattached_session_name = list-sessions --name --attached
		| where not $it.attached and ($it.name | str ends-with '*')
		| get 0?.name

	if $unattached_session_name == null {
		^tmux
	} else {
		^tmux attach -t $unattached_session_name
	}
}
