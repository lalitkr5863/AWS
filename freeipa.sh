#/bin/bash
s3_retention=3
retention=4
value=$(ls /var/lib/ipa/backup|wc -l)
user_validate()
{
sudo ipa-backup --online --data  &> /dev/null
if [ $? != 0 ] ;then
        echo "Only root OR sudo user with NOPASSWD can execute this command"
fi
}
greater()
{
      user_validate
}
equal()
{
        dir=$(ls /var/lib/ipa/backup|sort -r)
        args=($dir)
        last_dir=$(echo "${args[@]: -1}")
        rm -rf /var/lib/ipa/backup/${last_dir}
        user_validate
}
less()
{
while (( "$value" >= "$retention" ))
do
        dir=$(ls /var/lib/ipa/backup|sort -r)
        args=($dir)
        last_dir=$(echo "${args[@]: -1}")
        rm -rf /var/lib/ipa/backup/${last_dir}
        let value=" $value - 1 "
done
user_validate
}
if (( "$retention" > "$value" ))
then
        greater
elif (( "$retention" == "$value" ))
then
        equal
elif (( "$retention" < "$value" ))
then
        less
fi
latest_file=$(ls /var/lib/ipa/backup/|sort -n -r|sed -n 1p)
s3cmd sync /var/lib/ipa/backup/$latest_file s3://freeipa-bucket/ &>/dev/null
count=$(s3cmd ls s3://freeipa-bucket/|wc -l)
if  [ $count -gt $s3_retention ]; then
        file=$(s3cmd ls s3://freeipa-bucket/|sed -n 1p|cut -d '/' -f4)
        s3cmd rm s3://freeipa-bucket/$file --recursive
fi
