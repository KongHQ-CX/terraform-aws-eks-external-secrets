.PHONY: test build clean check_aws_env
SHELL := /usr/bin/env bash

deployment_name ?= vpc-a

check_tf_env:
ifndef deployment_name
$(error deployment_name needs to be set - deployment_name=my-deployment make build)
endif
ifndef email
$(error email needs to be set - email=myemail@mail.com make build)
endif

check_aws_env: 
ifndef AWS_PROFILE
$(error AWS_PROFILE is undefined)
endif

test: build

export TF_VAR_name=$(deployment_name)
export TF_VAR_zone_id=$(zone_id)
export TF_VAR_contact=$(email)

plan: check_aws_env check_tf_env
	@echo "terraform plan"; \
	terraform init; \
	terraform plan;

build: check_aws_env check_tf_env
	@echo "building the kong perf test env"; \
	terraform init; \
	terraform apply -auto-approve; \

clean: check_aws_env check_tf_env
	@echo "destroy the kong perf test env"; \
	terraform destroy -auto-approve; \
