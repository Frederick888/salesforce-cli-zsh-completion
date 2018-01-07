# remove SFDX spinner
export FORCE_SPINNER_DELAY=
export FORCE_SHOW_SPINNER=

# create the commands-list.json file
sfdx force:doc:commands:list --json | jq -r .result > commands-list.json
sfdx force:doc:commands:display --json | jq '.result[] | select((.command) != null)' > commands-display.json

completion=""
completion+="#compdef sfdx"

# header
completion+="\n"
completion+="\n# DESCRIPTION: Zsh completion script for the Salesforce CLI"
completion+="\n# AUTHOR: Wade Wegner"
completion+="\n# REPO: https://github.com/wadewegner/salesforce-cli-zsh-completion"
completion+="\n# LICENSE: https://github.com/wadewegner/salesforce-cli-zsh-completion/blob/master/LICENSE"
completion+="\n"
completion+="\nlocal -a _1st_arguments"
completion+="\n"
completion+="\n_1st_arguments=("

commands=""
while read name description
do
  name="$(echo $name | sed -e 's/:/\\:/g')"
  commands="${commands}\n\t\"$name\":\"$description\""
done <<< "$(jq -r 'to_entries[] | "\(.value.name)\t\(.value.description)"' commands-list.json)"

completion+=$commands
completion+="\n)"
completion+="\n"
completion+="\n_arguments '*:: :->command'"
completion+="\n"
completion+="\nif (( CURRENT == 1 )); then"
completion+="\n  _describe -t commands \"sfdx command\" _1st_arguments"
completion+="\n  return"
completion+="\nfi"
completion+="\n"

completion+="\nlocal -a _command_args"
completion+="\ncase \"\$words[1]\" in"

while read delimitedFullCommand
do

  fullCommandArray=($delimitedFullCommand)
  topic=${fullCommandArray[0]}
  command=${fullCommandArray[1]}
  fullCommand=$topic:$command

  completion+="\n  $fullCommand)"
  completion+="\n    _command_args=("

  delimitedFlags=$(jq -r '. | select((.command == "'$command'") and (.topic == "'$topic'")) | .flags | .[] | .name + "\t" + .description + "\t" + .char' commands-display.json)  #echo "jqFlags: " $delimitedFlags
  
  IFS=$'\n'
  flagArray=($delimitedFlags)
  IFS=$'\t'
  for flagArrayRow in "${flagArray[@]}"
  do
    flagArray2=($flagArrayRow)

    flagName=${flagArray2[0]}
    flagDescription=${flagArray2[1]}
    flagChar=${flagArray2[2]}

    # escape braces
    flagDescription=$(echo $flagDescription | sed -e "s/\[/\\\[/g")
    flagDescription=$(echo $flagDescription | sed -e "s/\]/\\\]/g")

    if [ "$flagChar" != "" ]
    then
      completion+="\n      '(-"$flagChar"|--"$flagName")'{-"$flagChar",--"$flagName"}'["$flagDescription"]' \\\\"
    else
      completion+="\n      '(--"$flagName")--"$flagName"["$flagDescription"]' \\\\"
    fi

  done
  IFS=' '

  completion+="\n    )"
  completion+="\n    ;;"
  
done <<< "$(jq -r '"\(.topic) \(.command)"' commands-display.json)"

completion+="\n  esac"
completion+="\n"
completion+="\n_arguments \\\\"
completion+="\n  \$_command_args \\\\"
completion+="\n  && return 0"

echo $completion > _sfdx