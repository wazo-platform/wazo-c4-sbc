.PHONY: dockerfile
dockerfile:
	docker build -t wazoplatform/wazo-c4-sbc:latest -f Dockerfile .
