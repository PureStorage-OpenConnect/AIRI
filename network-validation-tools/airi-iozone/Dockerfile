FROM ubuntu:latest
                                                                                                      
RUN apt-get update && apt-get install -y nfs-common rsh-client rsh-server                             
                                                                                                      
ADD http://mirrors.kernel.org/ubuntu/pool/multiverse/i/iozone3/iozone3_420-3_amd64.deb /tmp/iozone.deb
RUN dpkg -i /tmp/iozone.deb && rm /tmp/iozone.deb                                                     
                                                                                                      
RUN mkdir /tmp/ir                                                                                     
                                                                                                      
CMD ["/bin/bash"]

