echo "AWS user:"; read user
echo "AWS MFA token:"; read token
echo "AWS account number:"; read account

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN 

response_file=${TMPDIR}/response.json
echo Requesting token for MFA: ${token} for account ${account}
aws sts get-session-token --duration-seconds 43200 --serial-number arn:aws:iam::${account}:mfa/${user} --token-code ${token} > ${response_file}
echo Response file ${response_file}
echo "Run in the terminal"
echo "export AWS_ACCESS_KEY_ID=$(cat ${response_file} | jq .Credentials.AccessKeyId)"
echo "export AWS_SECRET_ACCESS_KEY=$(cat ${response_file} | jq .Credentials.SecretAccessKey)"
echo "export AWS_SESSION_TOKEN=$(cat ${response_file} | jq .Credentials.SessionToken)"
