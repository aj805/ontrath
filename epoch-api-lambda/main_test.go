package main

import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

func TestHandler(t *testing.T) {
	resp, err := handler(nil, events.APIGatewayProxyRequest{})
	if err != nil {
		t.Fatal(err)
	}
	if resp.StatusCode != 200 {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}
	if !strings.Contains(resp.Body, "The current epoch time") {
		t.Errorf("Unexpected body: %s", resp.Body)
	}

	var parsed map[string]int64
	json.Unmarshal([]byte(resp.Body), &parsed)
	if parsed["The current epoch time"] <= 0 {
		t.Errorf("Epoch time invalid: %d", parsed["The current epoch time"])
	}
}
