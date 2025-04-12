package handler

import (
	"encoding/json"
	"net/http"
	"time"
)

func EpochHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]int64{
		"The current epoch time": time.Now().Unix(),
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func HealthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}
