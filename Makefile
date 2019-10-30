.PHONY: dockerfile
dockerfile:
	docker build -t wazopbx/wazo-c4-sbc:latest -f Dockerfile .
