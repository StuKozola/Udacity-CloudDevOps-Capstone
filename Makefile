## This makefile contains instructions for
# Creating and activating a virtual environment
# Install required dependencies for running the model
# Perform linting
# Building docker container
# Uploading image to repository
# Running test models to populate mlflow runs
# Running mlflow locally (stand alone, minikube) or remote (with server url)

### variables
MLFLOW_SERVER=mlflow_server
DOCKERPATH=kozola/$(MLFLOW_SERVER)

### Setup ans installation
setup-env:
	# create a python virtual environment
	# source the evinronment: source ~/.devops/bin/activate
	python3 -m venv ~/.devops

install-env:
	# install requirements inside the virtual env for running mlflow locally
	. ~/.devops/bin/activate; \
	pip install --upgrade pip; \
	pip install pylint; \
	pip install mlflow[extras]; \
	deactivate;
	
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

### buld and test
lint:
	# lint dockerfiles: https://github.com/hadolint/hadolint
	hadolint Dockerfile
	# lint python source: https://www.pylint.org/

test-models:
	# train the model with four trial runs
	. ~/.devops/bin/activate; \
	python model/train.py 1 1; \
	python model/train.py 1 0.5; \
	python model/train.py 0.5 1; \
	python model/train.py 0.5 0.5; \
	deactivate;

build-image:
	# build the image and add tag
	sudo docker build --tag=${MLFLOW_SERVER} .
	# list images to verify build
	sudo docker image ls

### Deployment of artifacts
upload-image:
	# Upload docker image to repository
	export DOCKERPATH=$(DOCKERPATH); \
	echo "Docker ID and Image: $(DOCKERPATH)"; \
	sudo docker login; \
	sudo docker image tag ${MLFLOW_SERVER} ${DOCKERPATH};\
	sudo docker image push ${DOCKERPATH};

### Run
run-local:
	# run the installed version of mlflow (not in docker)
	. ~/.devops/bin/activate; \
	mlflow ui;

run-image:
	# run docker container locally
	sudo docker run -p 5000:5000 ${MLFLOW_SERVER}

run-repo:
	# grab the image stored in dockerhub and run it
	sudo docker pull ${DOCKERPATH}
	sudo sudo docker run -p 5000:5000 ${DOCKERPATH}


### local only (no docker, minikube)
install-local: setup-env install-env
build-local: test-models

### local docker image
install-local-img: setup-env install-env install-hadolint install-docker
build-local-img: test-models

#local-minikube:
#remote

clean:
	if [ -d "mlruns" ]; then rm -r mlruns; fi;