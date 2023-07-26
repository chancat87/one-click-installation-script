#!/usr/bin/env bash
#by spiritlhl
#from https://github.com/spiritLHLS/one-click-installation-script
#version: 2023.07.26


utf8_locale=$(locale -a 2>/dev/null | grep -i -m 1 -E "UTF-8|utf8")
if [[ -z "$utf8_locale" ]]; then
  echo "No UTF-8 locale found"
else
  export LC_ALL="$utf8_locale"
  export LANG="$utf8_locale"
  export LANGUAGE="$utf8_locale"
  echo "Locale set to $utf8_locale"
fi
cd /root >/dev/null 2>&1
ver="2023.07.26"
changeLog="一键安装jupyter环境"
source ~/.bashrc
red(){ echo -e "\033[31m\033[01m$1$2\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1$2\033[0m"; }
yellow(){ echo -e "\033[33m\033[01m$1$2\033[0m"; }
reading(){ read -rp "$(green "$1")" "$2"; }
clear
echo "#######################################################################"
echo "#                     ${YELLOW}一键安装jupyter环境${PLAIN}                             #"
echo "# 版本：$ver                                                    #"
echo "# 更新日志：$changeLog                                       #"
echo "# ${GREEN}作者${PLAIN}: spiritlhl                                                     #"
echo "# ${GREEN}仓库${PLAIN}: https://github.com/spiritLHLS/one-click-installation-script   #"
echo "#######################################################################"
echo "验证已支持的系统："
echo "Ubuntu 18/20/22 - 推荐，脚本自动挂起到后台"
echo "Debian 9/10/11 - 还行，需要手动挂起到后台，详看脚本运行安装完毕的后续提示"
echo "可能支持的系统：centos 7+，Fedora，Almalinux 8.5+"
red "本脚本尝试使用Miniconda3安装虚拟环境jupyter-env再进行jupyter和jupyterlab的安装，如若安装机器不纯净勿要轻易使用本脚本！"
yellow "执行脚本，之前有用本脚本安装过则直接打印设置的登陆信息，没安装过则进行安装再打印信息，如果已安装但未启动则自动启动后再打印信息"
yellow "如果是初次安装无脑y无脑回车即可，按照提示进行操作即可，安装完毕将在后台常驻运行"

check_china(){
    yellow "IP area being detected ......"
    if [[ -z "${CN}" ]]; then
        if [[ $(curl -m 6 -s https://ipapi.co/json | grep 'China') != "" ]]; then
            yellow "根据ipapi.co提供的信息，当前IP可能在中国"
            read -e -r -p "是否选用中国镜像完成相关组件安装? ([y]/n) " input
            case $input in
                [yY][eE][sS] | [yY])
                    echo "使用中国镜像"
                    CN=true
                    ;;
                [nN][oO] | [nN])
                    echo "不使用中国镜像"
                    ;;
                *)
                    echo "使用中国镜像"
                    CN=true
                    ;;
            esac
        else
            if [[ $? -ne 0 ]]; then
                if [[ $(curl -m 6 -s cip.cc) =~ "中国" ]]; then
                    yellow "根据cip.cc提供的信息，当前IP可能在中国"
                    read -e -r -p "是否选用中国镜像完成相关组件安装? [Y/n] " input
                    case $input in
                        [yY][eE][sS] | [yY])
                            echo "使用中国镜像"
                            CN=true
                            ;;
                        [nN][oO] | [nN])
                            echo "不使用中国镜像"
                            ;;
                        *)
                            echo "不使用中国镜像"
                            ;;
                    esac
                fi
            fi
        fi
    fi
}


install_jupyter() {
  rm -rf Miniconda3-latest-Linux-x86_64.sh*
  
  # Check if conda is already installed
  if ! command -v conda &> /dev/null; then
    # Install conda
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3-latest-Linux-x86_64.sh -b -u
    # added by Miniconda3 installer
    echo 'export PATH="$PATH:$HOME/miniconda3/bin:$HOME/miniconda3/condabin"' >> ~/.bashrc
    echo 'export PATH="$PATH:$HOME/.local/share/jupyter"' >> ~/.bashrc
    source ~/.bashrc
    sleep 1
    echo 'export PATH="/home/user/miniconda3/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    sleep 1
    # Add the necessary paths to your search path
    export PATH="/home/user/miniconda3/bin:$PATH"
    green "请关闭本窗口开一个新窗口再执行本脚本，否则无法加载一些预设的环境变量" && exit 0
  fi
  
  green "加载预设的conda环境变量成功，准备安装jupyter，无脑输入y和回车即可"
  
  # Create a new conda environment and install jupyter
  conda create -n jupyter-env python=3
  sleep 5
  source activate jupyter-env
  sleep 1
  conda install jupyter jupyterlab
  check_china
  if [[ -n "${CN}" && "${CN}" == true ]]; then
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
    conda config --set show_channel_urls yes
  fi

  # Add the following line to /etc/profile
  echo 'export PATH="$PATH:~/.local/share/jupyter"' >> /etc/profile
  # Execute the configuration
  source /etc/profile

  # Set username and password for Jupyter Server
  # jupyter notebook --generate-config
  # cp ~/.jupyter/jupyter_notebook_config.py ~/.jupyter/jupyter_server_config.py
  jupyter server --generate-config
  # echo "c.ServerApp.password = 'spiritlhl'" >> ~/.jupyter/jupyter_server_config.py
  # echo "c.ServerApp.username = 'spiritlhl'" >> ~/.jupyter/jupyter_server_config.py

  # Open port 13692 in firewall
  if command -v ufw &> /dev/null; then
      sudo ufw allow 13692/tcp
  elif command -v firewall-cmd &> /dev/null; then
      sudo firewall-cmd --add-port=13692/tcp --permanent
      sudo firewall-cmd --reload
  fi
  
  # Get the current system name
  ubuntu_version=$(lsb_release -rs)
  # Check if the Ubuntu version is 18.04, 20.04, or 22.04
  if [ "$ubuntu_version" == "18.04" ] || [ "$ubuntu_version" == "20.04" ] || [ "$ubuntu_version" == "22.04" ]; then
    # The system is Ubuntu 18.04, 20.04, or 22.04
    source activate jupyter-env
    sleep 1
    rm -rf nohup.out
    # Start Jupyter Server with port 13692 and host 0.0.0.0
    green "后台执行的pid的进程ID和输出日志文件名字如下"
    nohup jupyter lab --port 13692 --no-browser --ip=0.0.0.0 --allow-root & green $!
    sleep 5
    cat nohup.out
  else
    echo "你正在除了Ubuntu系统之外的系统执行，运行的最后几行可能有如下提示"
    yellow "nohup: failed to run command 'jupyter': No such file or directory"
    echo "非Ubuntu的系统你需要手动执行下面的命令"
    yellow "source activate jupyter-env"
    yellow "nohup jupyter lab --port 13692 --no-browser --ip=0.0.0.0 --allow-root"
    green "等待5秒后关闭本窗口，开新窗口执行下面的命令查看登陆信息"
    yellow "cat nohup.out"
    echo "非Ubuntu系统只有上面这样才能手动挂起jupyter后台执行"
  fi  
  
  # Add the specified paths to the PATH variable
  paths="./miniconda3/envs/jupyter-env/etc/jupyter:./miniconda3/envs/jupyter-env/bin/jupyter:./miniconda3/envs/jupyter-env/share/jupyter"
  export PATH="$paths:$PATH"

  # Remove duplicate paths from the PATH variable
  new_path=$(echo "$PATH" | tr ':' '\n' | awk '!x[$0]++' | tr '\n' ':')
  export PATH="$new_path"

  # Refresh the current shell
  source ~/.bashrc
  
  green "已安装jupyter lab的web端到外网端口13692上，请打开你的 外网IP:13692"
  green "初次安装会要求输入token设置密码，token详见上方打印信息或当前目录的nohup.out日志"
  green "同时已保存日志输出到当前目录的nohup.out中且已打印5秒日志如上"
  green "如果需要进一步查询，请关闭本窗口开一个新窗口再执行本脚本，否则无法加载一些预设的环境变量" 
  green "如果想要手动查询，输入 source activate jupyter-env && jupyter server list && conda deactivate 即可查询"
  exit 0
}

query_jupyter_info() {
  source activate jupyter-env > /dev/null 2>&1
  # Check if jupyter is installed
  if ! jupyter --version &> /dev/null; then
    echo "Error: Jupyter is not installed on this system."
    return 1
  fi
  
  source activate jupyter-env && jupyter server list && conda deactivate
  
  green "已查询登陆信息如上"
  green "如果想要手动查询，输入 source activate jupyter-env && jupyter server list && conda deactivate 即可查询"
}

main() {
  source activate jupyter-env > /dev/null 2>&1
  # Check if jupyter is installed
  if jupyter --version &> /dev/null; then
    green "Jupyter is already installed on this system."
    if ! (nc -z localhost 13692) > /dev/null 2>&1
    then
        source activate jupyter-env
        rm -rf nohup.out
        green "后台未启动jupyter，正在启动"
        nohup jupyter lab --port 13692 --no-browser --ip=0.0.0.0 --allow-root & green $!
        sleep 1
        jupyter lab
    fi
  else
    reading "Jupyter is not installed on this system. Do you want to install it? (y/n) " confirminstall
    echo ""

    # Check user's input and exit if they do not want to proceed
    if [ "$confirminstall" != "y" ]; then
      exit 0
    fi
    install_jupyter
  fi
  
  # Print the current info for Jupyter
  green "The current info for Jupyter:"
  query_jupyter_info
}

main
