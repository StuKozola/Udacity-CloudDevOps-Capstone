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
DEV_HOST=mlflow-dev
DEV_TRACKING=mlflow-server.local
DEV_MINIO=mlflow-minio.local

### Setup an installation
setup-ubuntu:
	# install dependecies for ubuntu
	sudo apt -y update
	sudo apt -y upgrade
	sudo apt -y install git
	sudo apt -y install make
	sudo apt -y install gnupg
	sudo apt -y install python3-venv

setup-env:
	# create a python virtual environment
	# source the evinronment: source ~/.devops/bin/activate
	python3 -m venv ~/.devops

set-dev-env:
	# set dev environment variables for local minikube testing
	echo  "MLFLOW_TRACKING_URI='http://$DEV_TRACKING'" > .env; \
	echo  "MLFLOW_S3_ENDPOINT_URL='http://$DEV_MINIO'" >> .env; \
	echo  "AWS_ACCESS_KEY_ID='minio'" >> .env; \
	echo  "AWS_SECRET_ACCESS_KEY='minio123'" >> .env; \
	echo  "TRACKING_HOST=$DEV_TRACKING" >> .env; \
	echo  "DEV_SERVER_HOST=$DEV_HOST" >> .env;

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
	sudo apt -y update
	sudo apt -y install apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
	sudo apt -y update
	apt-cache policy docker-ce
	sudo apt -y install docker-ce
	sudo groupadd -f docker
	sudo usermod -aG docker $$USER
	sudo systemctl status docker &

install-minikube:
	# install minikube and kubectl
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	sudo install minikube-linux-amd64 /usr/local/bin/minikube
	sudo curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
	minikube config set driver docker
	minikube delete

install-anchore:
	# anchore engine
	curl -LO https://engine.anchore.io/docs/quickstart/docker-compose.yaml
	# anchore cli
	sudo apt-get update
	sudo apt-get install python3-pip
	sudo pip3 install anchorecli
	export PATH="$$HOME/.local/bin/:$$PATH"
	# requires docker-compose
	sudo pip3 install docker-compose
	docker-compose up -d
	docker-compose ps
	docker-compose exec api anchore-cli system status
	docker-compose exec api anchore-cli system feeds list
	# wait for vulnerabilities to be ready
	docker-compose exec api anchore-cli system wait

### buld and test
lint:
	# lint dockerfiles: https://github.com/hadolint/hadolint
	hadolint Dockerfile
	# lint python source: https://www.pylint.org/

test-models:
	# train the model with four trial runs
	. ~/.devops/bin/activate; \
	if [ -f .env ]; then \
		export $$(grep -v '^#' .env | xargs); \
	fi; \
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

scan:
	docker compose exec api anchore-cli image add ${MLFLOW_SERVER}
	docker compose exec api anchore-cli image wait ${MLFLOW_SERVER}
	docker compose exec api anchore-cli image content ${MLFLOW_SERVER} os
	docker compose exec api anchore-cli image vuln ${MLFLOW_SERVER} all
	docker compose exec api anchore-cli evaluate check ${MLFLOW_SERVER}


### Deployment of artifacts
upload-image:
	# Upload docker image to repositoryM1
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

run-local-k8: set-dev-env
	minikube start
	kubectl get po -A
	minikube addons enable ingress
	sudo chmod +x insert-hosts.sh
	./insert-hosts.sh `minikube ip` ${DEV_HOST} ${DEV_TRACKING} ${DEV_MINIO}

	# run local minikube configuration
	kubectl create -f k8/postgres.yml
	kubectl create -f k8/minio.yml
	kubectl create -f k8/mlflow-server.yml
	kubectl get services

### local only (no docker, no minikube)
install-local: setup-env install-env
build-local: test-models

### local with minikube and docker
install-local-k8: setup-env set-dev-env install-env install-hadolint install-docker install-anchore install-minikube
build-local-k8: lint build-img scan upload-img

### install for docker build only
install: setup-env install-env install-hadolint install-docker

clean:
	if [ -d "mlruns" ]; then rm -r mlruns; fi;
	if [ -f "minikube-linux-amd64" ]; then rm -f minikube-linux-amd64; fi;
	if [ -f "kubectl" ]; then rm -f kubectl; fi;
	if [ -f ".env" ]; then rm -f .env; fi;
	if [ -f "anchore.env" ]; then rm -f anchore.env; fi;
	if [ -f "docker-compose.yaml" ]; then rm -f docker-compose.yaml; fi;

destroy:
	minikube stop
	minikube delete --all