#!/bin/bash
source ~/.setup.1password.sh
AK=$(op --account $OP_ACCOUNT_BARENBOIM read "op://$OP_VAULT_CHESSBYTE/$OP_ITEM_AWS_CHESSBYTE/Programmatic Access/AWS access key id")
SK=$(op --account $OP_ACCOUNT_BARENBOIM read "op://$OP_VAULT_CHESSBYTE/$OP_ITEM_AWS_CHESSBYTE/Programmatic Access/AWS secret access key")
printf '{"Version":1,"AccessKeyId":"%s","SecretAccessKey":"%s"}' "$AK" "$SK"
