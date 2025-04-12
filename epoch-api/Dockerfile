FROM golang:1.23 AS builder
WORKDIR /app
COPY . .
RUN go test internal/handler/handler_test.go
RUN go build -o epoch-api ./cmd/main.go

EXPOSE 8080
ENTRYPOINT ["/app/epoch-api"]
