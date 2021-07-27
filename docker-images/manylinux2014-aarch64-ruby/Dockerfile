# See: https://github.com/pypa/manylinux
# and: https://github.com/pypa/python-manylinux-demo
FROM quay.io/pypa/manylinux2014_aarch64

###############################################################################
# Basics
###############################################################################
RUN yum -y install sudo \
    && yum clean all \
    && cmake --version \
    && ctest --version

###############################################################################
# Python/AWS CLI
###############################################################################
RUN /opt/python/cp39-cp39/bin/python -m pip install --upgrade pip setuptools virtualenv \
    && /opt/python/cp39-cp39/bin/python -m pip install --upgrade awscli \
    && ln -s `find /opt -name aws` /usr/local/bin/aws \
    && which aws \
    && aws --version

###############################################################################
# nodejs/npm
###############################################################################
RUN curl -sL https://rpm.nodesource.com/setup_12.x | sudo bash -
RUN sudo yum -y install nodejs && node --version

###############################################################################
# Install RVM and Ruby
###############################################################################
RUN yum -y install git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel \
    && curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
    && curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - \
    && curl -sSL https://get.rvm.io | bash -s stable --ruby \
    && source /usr/local/rvm/scripts/rvm \

SHELL ["/bin/bash", "-l", "-c"]

# Install clang/gcc
RUN yum -y install devtoolset-7 llvm-toolset-7.0.aarch64 centos-release-scl clang \
    && scl enable llvm-toolset-7.0 bash

###############################################################################
# Install entrypoint
###############################################################################
ADD entrypoint.sh /usr/local/bin/builder
RUN chmod a+x /usr/local/bin/builder
ENTRYPOINT ["/usr/local/bin/builder"]
