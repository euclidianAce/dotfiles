use std

export def command [...arguments] {
	^tmux ...$arguments
}

export def list-sessions-vars [
       --activity             # Time of session last activity
       --alerts               # List of window indexes with alerts
       --attached             # Number of clients session is attached to
       --attached-list        # List of clients session is attached to
       --created              # Time session created
       --format               # true if format is for a session
       --group                # Name of session group
       --group-attached       # Number of clients sessions in group are attached to
       --group-attached-list  # List of clients sessions in group are attached to
       --group-list           # List of sessions in group
       --group-many-attached  # true if multiple clients attached to sessions in group
       --group-size           # Size of session group
       --grouped              # true if session in a group
       --id                   # Unique session ID
       --last-attached        # Time session last attached
       --many-attached        # true if multiple clients attached
       --marked               # true if this session contains the marked pane
       --name                 # Session name
       --path                 # Working directory of session
       --stack                # Window indexes in most recent order
       --windows              # Number of windows in session
] {
	let transform = [[name,include,tag];
		[ 'activity',             $activity,            null ]
		[ 'alerts',               $alerts,              null ]
		[ 'attached',             $attached,            "bool" ]
		[ 'attached_list',        $attached_list,       null ]
		[ 'created',              $created,             null ]
		[ 'format',               $format,              "bool" ]
		[ 'group',                $group,               null ]
		[ 'group_attached',       $group_attached,      "int" ]
		[ 'group_attached_list',  $group_attached_list, null ]
		[ 'group_list',           $group_list,          null ]
		[ 'group_many_attached',  $group_many_attached, "bool" ]
		[ 'group_size',           $group_size,          "int" ]
		[ 'grouped',              $grouped,             "bool" ]
		[ 'id',                   $id,                  null ]
		[ 'last_attached',        $last_attached,       null ]
		[ 'many_attached',        $many_attached,       "bool" ]
		[ 'marked',               $marked,              "bool" ]
		[ 'name',                 $name,                null ]
		[ 'path',                 $path,                null ]
		[ 'stack',                $stack,               null ]
		[ 'windows',              $windows,             "int" ]
	]

	let names_and_format = $transform
		| where include
		| reduce --fold [] {|it, acc|
			$acc | append {name: $it.name, format: ('#{session_' + $it.name + '}')}
		}

	let format_string = $names_and_format | get format | str join ';'

	mut data = (^tmux list-sessions -F $format_string e> (std null-device))
		| from csv --noheaders --separator ';'
		| rename ...($names_and_format | get name)

	for tf in ($transform | where include) {
		$data = ($data
			| update $tf.name {|it| $it
				| get $tf.name
				| match $tf.tag {
					"bool" => { into bool },
					"int" => { into int },
					_ => { echo $"($in)" }
				}
			}
		)
	}

	$data
}

export def new-or-attach [] {
	let unattached_session_name = list-sessions-vars --name --attached
		| where not attached 
		| where ($it.name | str ends-with '*' | not $in)
		| get 0?.name

	if $unattached_session_name == null {
		^tmux
	} else {
		^tmux attach -t $unattached_session_name
	}
}
