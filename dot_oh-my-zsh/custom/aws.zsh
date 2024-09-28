function aws-clean() {
  echo "This will unset your AWS environment variables"
  echo -n "Do you want to proceed? (Y/n): "
  read response

  # Check the user's response
  if [[ "$response" =~ ^[Nn]$ ]]; then
    echo "Cancelling"
  else
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
  fi
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

function aws-sso() {
  list_profiles() {
      touch ~/.aws/config
      grep -v "^#" ~/.aws/config | grep -o '\[profile[^][]*]' | cut -d "[" -f2 | cut -d "]" -f1 | cut -d " " -f2
  }

  # Display the list of instances and ask the user to select one
  echo "Here's a list of available profiles from ~/.aws/config:"
  instances=($(list_profiles))
  len=${#instances[@]}

  for (( i=1; i<=$len; i+=1 )); do
      echo "$((i)): ${instances[$i]}"
  done

  echo -e "\nPlease choose an profile by number:"
  read INSTANCE_NUMBER

  # Extract the instance ID based on the user's choice
  index=$((INSTANCE_NUMBER))
  export AWS_PROFILE=${instances[$index]}
  echo "Using AWS PROFILE ($AWS_PROFILE)"

  if ! aws sts get-caller-identity --no-cli-pager; then
      # If the command fails, attempt to login with SSO
      echo "Invalid credentials or another error occurred. Attempting to login with SSO..."
      aws sso login
  fi
}
