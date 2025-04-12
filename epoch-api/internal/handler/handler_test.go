package handler_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"ajontra/epochalypse/epoch-api/internal/handler"
)

func TestEpochHandler(t *testing.T) {
	req := httptest.NewRequest("GET", "/", nil)
	w := httptest.NewRecorder()

	handler.EpochHandler(w, req)

	if status := w.Code; status != http.StatusOK {
		t.Fatalf("Expected status 200, got %d", status)
	}

	body := w.Body.String()
	if body == "" || !containsEpoch(body) {
		t.Errorf("Unexpected response body: %s", body)
	}
}

func containsEpoch(body string) bool {
	return len(body) > 0 && body[0] == '{'
}
