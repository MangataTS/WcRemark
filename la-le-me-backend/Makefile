.PHONY: build run test lint clean docker-build docker-up docker-down

build:
	go build -o bin/server ./cmd/server

run:
	go run ./cmd/server

test:
	go test ./... -v -cover

lint:
	go vet ./...

clean:
	rm -rf bin/

docker-build:
	docker build -t la-le-me-api -f docker/Dockerfile .

docker-up:
	docker-compose -f docker/docker-compose.yml up -d

docker-down:
	docker-compose -f docker/docker-compose.yml down

docker-logs:
	docker-compose -f docker/docker-compose.yml logs -f api
