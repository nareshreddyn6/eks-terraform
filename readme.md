
# these are important

aws eks update-kubeconfig --name selfeks --region us-east-1
ssh-keygen -m pem -f nodekey 

copy .pub key file conetnt and paste in aws_key_pair public_key


terraform output kubeconfig
terraform output kubeconfig >~/.kube/config

--kubelet-extra-args '--node-labels="node.kubernetes.io/node-group=myautogroup"'


curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl

chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc

mkdir -p ~/.kube

echo 'export KUBECONFIG=$KUBECONFIG:~/.kube/config' >> ~/.bashrc

url "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt update
apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install


