FROM golang:1.23 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go test
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bootstrap main.go && chmod +x bootstrap

FROM public.ecr.aws/lambda/go:1
COPY --from=builder /app/bootstrap ${LAMBDA_RUNTIME_DIR}

CMD [ "handler" ]
