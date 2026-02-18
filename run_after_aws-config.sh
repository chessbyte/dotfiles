#!/bin/bash
# Auto-generate ~/.aws/config by concatenating all aws profile configs
mkdir -p ~/.aws
cat ~/.oh-my-zsh/custom/aws-profiles/*.config > ~/.aws/config
echo "AWS config updated with $(grep -c '\[profile' ~/.aws/config) profiles"
