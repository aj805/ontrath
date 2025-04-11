package main

import (
	"context"
	"encoding/json"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	body, err := json.Marshal(map[string]int64{
		"The current epoch time": time.Now().Unix(),
	})
	if err != nil {
		return events.APIGatewayProxyResponse{StatusCode: 500}, err
	}

	imageTag := os.Getenv("IMAGE_TAG")

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Content-Type": "application/json",
			"Image-Tag":    imageTag,
		},
		Body: string(body),
	}, nil
}

func main() {
	lambda.Start(handler)
}
