#!/bin/bash

file="/var/lib/libvirt/images/kube1.qcow2"
if [ -f "$file" ]
then 	
		echo "$file found."
else 	
		wget ftp://192.168.10.254/pub/kube1.qcow2  -O /var/lib/libvirt/images/kube1.qcow2
fi


#down and delete

virsh  destroy  master
virsh  destroy  node1
virsh  destroy  node2
virsh  destroy  registry
virsh  undefine   master
virsh  undefine   node1
virsh  undefine   node2 
virsh  undefine   registry



# removing  snapshost
rm  -vrf  /var/lib/libvirt/images/master.qcow2
rm  -vrf  /var/lib/libvirt/images/node1.qcow2
rm  -vrf  /var/lib/libvirt/images/node2.qcow2
rm  -vrf  /var/lib/libvirt/images/registry.qcow2


# creating again 

qemu-img create -f qcow2 -b  /var/lib/libvirt/images/kube1.qcow2  /var/lib/libvirt/images/master.qcow2
qemu-img create -f qcow2 -b  /var/lib/libvirt/images/kube1.qcow2  /var/lib/libvirt/images/node1.qcow2
qemu-img create -f qcow2 -b  /var/lib/libvirt/images/kube1.qcow2  /var/lib/libvirt/images/node2.qcow2
qemu-img create -f qcow2 -b  /var/lib/libvirt/images/kube1.qcow2  /var/lib/libvirt/images/registry.qcow2






#  booting  vms

virt-install --name master --ram 4096  --vcpu 2 --noautoconsole  --disk path=/var/lib/libvirt/images/master.qcow2 --import  --os-type linux --os-variant=rhel7
sleep 10

virt-install --name node1 --ram 1500  --vcpu 1 --noautoconsole --disk path=/var/lib/libvirt/images/node1.qcow2  --import   --os-type linux --os-variant=rhel7
sleep 10

virt-install --name node2 --ram 1500   --vcpu 1 --noautoconsole --disk path=/var/lib/libvirt/images/node2.qcow2   --import  --os-type linux --os-variant=rhel7
sleep 10
virt-install --name registry --ram 1000  --vcpu 1 --noautoconsole --disk path=/var/lib/libvirt/images/registry.qcow2   --import  --os-type linux --os-variant=rhel7
sleep 10

##greping ips

m=`virsh dumpxml master | grep -i  'mac address' | cut -d"'" -f2`
master=`arp -n | grep -i -w "$m" | awk '{print $1}'`
echo $master

m=`virsh dumpxml master | grep -i  'mac address' | cut -d"'" -f2`
node1=`arp -n | grep -i -w "$m" | awk '{print $1}'`
echo $node1


m=`virsh dumpxml master | grep -i  'mac address' | cut -d"'" -f2`
node2=`arp -n | grep -i -w "$m" | awk '{print $1}'`
echo $node2

m=`virsh dumpxml master | grep -i  'mac address' | cut -d"'" -f2`
registry=`arp -n | grep -i -w "$m" | awk '{print $1}'`
echo $registry

##setting hostname
sshpass -p 'redhat' ssh $master 'hostnamectl set-hostname master.example.com'
sshpass -p 'redhat' ssh $node1 'hostnamectl set-hostname  node1.example.com'
sshpass -p 'redhat' ssh $node2 'hostnamectl set-hostname node2.example.com'
sshpass -p 'redhat' ssh $registry 'hostnamectl set-hostname registry.example.com'


##ENtry in hosts file
sshpass -p 'redhat'  ssh $master   'echo "$master master  master.example.com" >> /etc/hosts  ; echo  "$node1 node1 node1.example.com" >> /etc/hosts  ; echo "$node2 node2 node2.example.com  >> /etc/hosts " ; echo "$registry  registry registry.example.com"  >> /etc/hosts'

##set up ssh keyid #######




##sending hosts file entry
sshpass -p 'redhat' scp -o StrictHostKeyChecking=no /etc/hosts root@node1:/etc/hosts
sshpass -p 'redhat' scp -o StrictHostKeyChecking=no /etc/hosts root@node2:/etc/hosts
sshpass -p 'redhat' scp -o StrictHostKeyChecking=no /etc/hosts root@registry:/etc/hosts





################################### OPTIONAL ###############################################
#cat <<X  >>/etc/yum.repos.d/main.repo
#[a]
#baseurl=ftp://192.168.10.254/pub/rhel75

#gpgcheck=0
#[b]
#baseurl=ftp://192.168.10.254/pub/adhoc/kubernetes
#gpgcheck=0
#X


#sshpass -p 'redhat' scp -o StrictHostKeyChecking=no /etc/yum.repos.d/main.repo root@$master:/etc/yum.repos.d/
#sshpass -p 'redhat' scp -o StrictHostKeyChecking=no /etc/yum.repos.d/main.repo root@$node1:/etc/yum.repos.d/
#sshpass -p 'redhat' scp -o StrictHostKeyChecking=no /etc/yum.repos.d/main.repo root@$noe2:/etc/yum.repos.d/
#sshpass -p 'redhat' scp -o StrictHostKeyChecking=no /etc/yum.repos.d/main.repo root@$registry:/etc/yum.repos.d/

