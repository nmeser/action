# "aws ec2 describe-instances" ile bütün ec2 'ların bilgilerini json formatında alıyoruz. 
# " --query " komutu ile de almak istediğiz outputları json output'dan çekiyoruz 
# " --filter " komutu ile de 'running' state de olan ec2'ları filtreliyoruz.
# " --output table" komutu ile tablo haline bastırıyoruz.

aws ec2 describe-instances \
    --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" \
    --filters "Name=instance-state-name,Values=running" \
    --output table


aws ec2 describe-instances \
    --query "Reservations[*].Instances[*].{InstanceId:InstanceId,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}" \
    --filters "Name=instance-state-name,Values=running" \
    --output table