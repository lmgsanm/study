ceph-deploy osd create ceph01:/dev/sdb

ceph-deploy osd create ceph01:/dev/sdc

ceph-deploy osd create ceph01:/dev/sdd

 

ceph-deploy osd create ceph02:/dev/sdb

ceph-deploy osd create ceph02:/dev/sdc

ceph-deploy osd create ceph02:/dev/sdd

 

ceph-deploy osd create ceph03:/dev/sdb

ceph-deploy osd create ceph03:/dev/sdc

ceph-deploy osd create ceph03:/dev/sdd

 

ceph-deploy osd create ceph01:/dev/sdb

ceph-deploy osd activate ceph01:/dev/sdb

 

systemctl  stop firewalld

systemctl  disable firewalld

sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config

 

ceph-deploy install ceph01 ceph02 ceph03

ceph-deploy new ceph01 ceph02 ceph03

ceph-deploy mon create ceph01 ceph02 ceph03

 

ceph-deploy --overwrite-conf  mon create-initial

/etc/yum.repos.d/ceph-deploy.repo

[hammerx86_64]

name="hammer X86_64"

baseurl=https://mirrors.ustc.edu.cn/ceph/rpm-hammer/el7/x86_64/

enabled=1

\#gpgcheck=0

 

[hammernoarch]

name="hammer noarch"

baseurl=https://mirrors.ustc.edu.cn/ceph/rpm-hammer/el7/noarch/

enabled=1

\#gpgcheck=0

 

yum -y install install ceph-deploy --nopgpcheck

 

yum -y install ntp chnroy

 

ceph-deploy --overwrite-conf config push ceph01 ceph02 ceph03

 

cat /etc/ceph/ceph.conf

[global]

fsid = a1d5a439-0055-4420-b46c-2042e5c509e9

mon_initial_members = ceph01, ceph02, ceph03

mon_host = 192.168.1.10,192.168.1.11,192.168.1.12

auth_cluster_required = cephx

auth_service_required = cephx

auth_client_required = cephx

mon clock drift allowed = 2

mon clock drift warn backoff = 30

 

 

[root@ceph03 ~]# ceph -s

  cluster a1d5a439-0055-4420-b46c-2042e5c509e9

   health HEALTH_ERR

​      clock skew detected on mon.ceph02, mon.ceph03

​      no osds

​      Monitor clock skew detected

   monmap e1: 3 mons at {ceph01=192.168.1.10:6789/0,ceph02=192.168.1.11:6789/0,ceph03=192.168.1.12:6789/0}

​      election epoch 8, quorum 0,1,2 ceph01,ceph02,ceph03

   osdmap e1: 0 osds: 0 up, 0 in

​      flags sortbitwise,require_jewel_osds

   pgmap v2: 64 pgs, 1 pools, 0 bytes data, 0 objects

​      0 kB used, 0 kB / 0 kB avail

​         64 creating

 

systemctl restart ceph-mon.target

 

 

\#ceph-deploy mgr create ceph01 ceph02 ceph03

 

 

[root@ceph01 ~]# ceph -s

  cluster a1d5a439-0055-4420-b46c-2042e5c509e9

   health HEALTH_ERR

​      64 pgs are stuck inactive for more than 300 seconds

​      64 pgs stuck inactive

​      64 pgs stuck unclean

​      no osds

   monmap e1: 3 mons at {ceph01=192.168.1.10:6789/0,ceph02=192.168.1.11:6789/0,ceph03=192.168.1.12:6789/0}

​      election epoch 24, quorum 0,1,2 ceph01,ceph02,ceph03

   osdmap e1: 0 osds: 0 up, 0 in

​      flags sortbitwise,require_jewel_osds

   pgmap v2: 64 pgs, 1 pools, 0 bytes data, 0 objects

​      0 kB used, 0 kB / 0 kB avail

​         64 creating

 

 

ceph pg ls-by-pool rbd

ceph osd getcrushmap -o /tmp/crushmap.obj

crushtool -d /tmp/crushmap.obj -o /tmp/crushmap.txt

 

 

cat /etc/yum.repos.d/CentOS-Base.repo

[base]

name=CentOS-$releasever - Base - mirrors.aliyun.com

failovermethod=priority

baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/

gpgcheck=1

gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

 

\#released updates

[updates]

name=CentOS-$releasever - Updates - mirrors.aliyun.com

failovermethod=priority

baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/

gpgcheck=1

gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

 

\#additional packages that may be useful

[extras]

name=CentOS-$releasever - Extras - mirrors.aliyun.com

failovermethod=priority

baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/

gpgcheck=1

gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

 

\#additional packages that extend functionality of existing packages

[centosplus]

name=CentOS-$releasever - Plus - mirrors.aliyun.com

failovermethod=priority

baseurl=http://mirrors.aliyun.com/centos/$releasever/centosplus/$basearch/

gpgcheck=1

enabled=0

gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

 

\#contrib - packages by Centos Users

[contrib]

name=CentOS-$releasever - Contrib - mirrors.aliyun.com

failovermethod=priority

baseurl=http://mirrors.aliyun.com/centos/$releasever/contrib/$basearch/

gpgcheck=1

enabled=0

gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

 