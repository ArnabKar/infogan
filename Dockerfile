FROM nvidia/cuda:7.5-cudnn5-devel

# Install dependencies for OpenBLAS and Torch
RUN apt-get update \
 && apt-get install -y \
    build-essential git gfortran \
    cmake curl wget unzip libreadline-dev libjpeg-dev libpng-dev ncurses-dev \
    imagemagick libssl-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install OpenBLAS
RUN git clone https://github.com/xianyi/OpenBLAS.git /tmp/OpenBLAS \
 && cd /tmp/OpenBLAS \
 && [ $(getconf _NPROCESSORS_ONLN) = 1 ] && export USE_OPENMP=0 || export USE_OPENMP=1 \
 && make -j $(getconf _NPROCESSORS_ONLN) NO_AFFINITY=1 \
 && make install \
 && rm -rf /tmp/OpenBLAS

# Install Torch
ARG TORCH_DISTRO_COMMIT=4bfc2da1e78069f98936ba8f1fc7e8b689699e97
RUN git clone https://github.com/torch/distro.git ~/torch --recursive \
 && cd ~/torch \
 && git checkout "$TORCH_DISTRO_COMMIT" \
 && ./install.sh

# Export Torch environment variables
ENV LUA_PATH='/root/.luarocks/share/lua/5.1/?.lua;/root/.luarocks/share/lua/5.1/?/init.lua;/root/torch/install/share/lua/5.1/?.lua;/root/torch/install/share/lua/5.1/?/init.lua;./?.lua;/root/torch/install/share/luajit-2.1.0-alpha/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua' \
    LUA_CPATH='/root/.luarocks/lib/lua/5.1/?.so;/root/torch/install/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so' \
    PATH=/root/torch/install/bin:$PATH \
    LD_LIBRARY_PATH=/root/torch/install/lib:$LD_LIBRARY_PATH \
    DYLD_LIBRARY_PATH=/root/torch/install/lib:$DYLD_LIBRARY_PATH

# Install CuDNN Torch bindings
RUN luarocks install https://raw.githubusercontent.com/soumith/cudnn.torch/R5/cudnn-scm-1.rockspec

# Install weight initialisation package
RUN luarocks install nninit

# Install Torchnet framework
RUN luarocks install torchnet

# Set working dir
RUN mkdir /app
WORKDIR /app

# Create a non-privileged user for running commands inside the container
RUN adduser --disabled-password --gecos '' appuser \
 && chown -R appuser:appuser /app \
 && chmod +rx /root \
 && chown -R appuser:appuser /root/torch
USER appuser

CMD ["bash"]