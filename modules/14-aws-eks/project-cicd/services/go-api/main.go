package main

import (
	"encoding/json"
	"net/http"
)

func main() {
	http.HandleFunc("/health", healthHandler)
	_ = http.ListenAndServe(":8080", nil)
}

func healthHandler(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{
		"status":  "ok",
		"service": "go-api",
	})
}
