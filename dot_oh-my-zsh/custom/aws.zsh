function aws-clean() {
  unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
  echo "AWS environment variables unset"
}

function aws-sso() {
  local profile
  profile=$(grep '\[profile ' ~/.aws/config \
    | sed 's/\[profile \(.*\)]/\1/' \
    | sort \
    | fzf --prompt="AWS Profile> " --height=40% --reverse)
  [[ -z "$profile" ]] && return
  export AWS_PROFILE="$profile"
  echo "Using AWS_PROFILE=$AWS_PROFILE"
  aws sts get-caller-identity --no-cli-pager || aws sso login
}

function aws-rds() {
if [[ -z "$AWS_PROFILE" ]]
	then
		aws-sso
	else
		echo "AWS_PROFILE is set to: $AWS_PROFILE"
	fi
	list_instances () {
		aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='aws:cloudformation:stack-name'].Value | [0], State.Name]" --output text | grep "running"
	}
	echo "You didn't provide an instance ID. Here's a list of running instances:"
	list_instances
	echo "Here's a list of available instances:"
	instances=($(list_instances))
	len=${#instances[@]}
	for ((i=0; i<$len; i+=3 )) do
		echo "$((i/3 + 1)). ID: ${instances[$i+1]} Name: ${instances[$i+2]}"
	done
	if [[ ${#instances[@]} -eq 3 ]]
	then
		INSTANCE_ID=${instances[1]}
		echo "Only one instance found. Using ID: ${instances[1]} Name: ${instances[2]}"
	else
		echo "Multiple instances found. Please specify which one to use."
		echo -e "\nPlease choose an instance by number:"
		read INSTANCE_NUMBER
		index=$(( ((INSTANCE_NUMBER-1) * 3 ) + 1))
		INSTANCE_ID=${instances[$index]}
		echo "Using instance ID ($INSTANCE_ID)"
	fi
	DEFAULT_LOCAL_PORT=5432
	echo "Enter local port for port forwarding (default: ${DEFAULT_LOCAL_PORT}):"
	read LOCAL_PORT
	LOCAL_PORT=${LOCAL_PORT:-$DEFAULT_LOCAL_PORT}
	aws ssm start-session --target $INSTANCE_ID --document-name "AWS-StartPortForwardingSession" --parameters "localPortNumber=${LOCAL_PORT},portNumber=5432" --region us-east-1
}
