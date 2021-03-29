## This makefile contains instructions for
# Creating and activating a virtual environment
# Install required dependencies for running the model
# 

setup:
	# create a python virtual environment
	# source the evinronment: source ~/.devops
	python3 -m venv ~/.devops

install-env:
	# install requirments inside the virtual env
	. ~/.devops/bin/activate
	pip install --upgrade pip
	pip install pylint
	
install-hadolint:
	# install hadolint for Dockerfiles
	sudo wget -O /bin/hadolint https://github.com/hadolint/hadolint/releases/download/v1.22.1/hadolint-Linux-x86_64
	sudo chmod +x /bin/hadolint

install-docker:
	# install docker
	sudo apt update
	sudo apt install apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
	sudo apt update
	apt-cache policy docker-ce
	sudo apt install docker-ce
	sudo systemctl status docker

install-minikube:
	# install minikube
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	sudo install minikube-linux-amd64 /usr/local/bin/minikube

install-all: install-env install-hadolint install-docker install-minikube

lint:
	# lint dockerfiles: https://github.com/hadolint/hadolint
	hadolint Dockerfile
	# lint python source: https://www.pylint.org/

test:
	# train the model trial 1
	
	# train the model trial 2

