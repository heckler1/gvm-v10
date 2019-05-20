FROM centos:7
LABEL maintainer="stephen@sheckler.info"

# Proxy optimization
RUN sed -i "s/^mirrorlist/#mirrorlist/g" /etc/yum.repos.d/CentOS-Base.repo
RUN sed -i "s/^#base/base/g" /etc/yum.repos.d/CentOS-Base.repo

# Install the texlive repo
ADD etc/yum.repos.d/texlive.repo /etc/yum.repos.d/texlive.repo

# Install wget so that we can install the atomicorp repo
# Install IUS for python3
RUN yum -y install wget \
                   https://centos7.iuscommunity.org/ius-release.rpm

# Install the atomicorp repo, with default settings
RUN cd /root; NON_INT=1 wget -q -O - https://updates.atomicorp.com/installers/atomic | sh

# Cleanup a little
RUN yum clean all

# Update our container
RUN yum -y update

# Install GVM dependencies
RUN yum -y install alien \
                   bzip2 \
                   useradd \
                   net-tools \
                   openssh \
                   texlive-changepage \
                   texlive-titlesec \
                   texlive-collection-latexextra \
                   python36u \
                   python36u-pip

# Prep dependencies
RUN mkdir -p /usr/share/texlive/texmf-local/tex/latex/comment
RUN texhash

# Install GVM
RUN yum -y install greenbone-vulnerability-manager \
                   OSPd-nmap \
                   OSPd

# Install the GVM CLI
RUN pip3.6 install gvm-tools

# Install Arachni Web App scanning framework
RUN wget https://github.com/Arachni/arachni/releases/download/v1.5.1/arachni-1.5.1-0.5.12-linux-x86_64.tar.gz \
      && tar xvf arachni-1.5.1-0.5.12-linux-x86_64.tar.gz \
      && mv arachni-1.5.1-0.5.12 /opt/arachni \
      && ln -s /opt/arachni/bin/* /usr/local/bin/ \
      && rm -rf arachni*

# More cleanp
RUN rm -rf /var/cache/yum/*

# Add a script to update NVTs
ADD usr/local/sbin/update_feeds.sh /usr/local/sbin/update_feeds.sh

# Get the latest NVTs/CERT/SCAP data
RUN sh /usr/local/sbin/update_feeds.sh

# Install our entrypoint
ADD usr/local/sbin/run.sh /usr/local/sbin/run.sh

# Install our configs
ADD etc/redis.conf /etc/redis.conf
ADD etc/sysconfig/gsad /etc/sysconfig/gsad

# We add our scan script at the end for quick rebuild on modification
ADD usr/local/sbin/run_scan.sh /usr/local/sbin/run_scan.sh

ENTRYPOINT [ "bash", "/usr/local/sbin/run.sh" ] 
EXPOSE 443