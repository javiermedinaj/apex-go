package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

// Cargar desde variables de entorno
var (
	InstanceURL = os.Getenv("SALESFORCE_INSTANCE_URL")
	AccessToken = os.Getenv("SALESFORCE_ACCESS_TOKEN")
)

type LeadInput struct {
	FullName string `json:"fullName"`
	Email    string `json:"email"`
	Company  string `json:"company"`
}

type SalesforcePayload struct {
	FullName string `json:"fullName"`
	Email    string `json:"email"`
	Company  string `json:"company"`
	Tier     string `json:"tier"`
	Source   string `json:"source"`
}

type LegacyRecord struct {
	Domain string `json:"domain"`
	Tier   string `json:"tier"`
}

func checkLegacySystem(email string) string {
	components := strings.Split(email, "@")
	if len(components) != 2 {
		return "STANDARD"
	}
	domain := components[1]

	file, _ := os.ReadFile("legacy_db.json")
	var db []LegacyRecord
	json.Unmarshal(file, &db)

	for _, record := range db {
		if record.Domain == domain {
			return record.Tier
		}
	}
	return "STANDARD"
}

func handleLead(w http.ResponseWriter, r *http.Request) {
	// CORS para que astro pueda conectarse, luego pasar a configuración más segura
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
	if r.Method == "OPTIONS" {
		return
	}

	// Recibir datos de Astro o del frontend
	var input LeadInput
	body, _ := io.ReadAll(r.Body)
	json.Unmarshal(body, &input)
	fmt.Printf("Recibido: %s (%s)\n", input.FullName, input.Email)

	// orquestacion de pasos
	tier := checkLegacySystem(input.Email)
	//print en consola
	fmt.Printf("Análisis de Legacy DB: Cliente es %s\n", tier)

	// payload para Salesforce
	sfPayload := SalesforcePayload{
		FullName: input.FullName,
		Email:    input.Email,
		Company:  input.Company,
		Tier:     tier,
		Source:   "ForgeAI Web Landing",
	}
	// preparar como lista
	finalList := []SalesforcePayload{sfPayload}
	jsonToSend, _ := json.Marshal(finalList)

	// 4. Enviar a Salesforce
	endpoint := InstanceURL + "/services/apexrest/B2BLeads/"
	req, _ := http.NewRequest("POST", endpoint, bytes.NewBuffer(jsonToSend))
	req.Header.Set("Authorization", "Bearer "+AccessToken)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		http.Error(w, "Error Salesforce", 500)
		return
	}
	defer resp.Body.Close()

	// Responder a Astro
	w.Write([]byte("Procesado correctamente"))
}

// --- HEALTH CHECK (para AWS ALB/ECS) ---
func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "healthy",
		"service": "forgeai-middleware",
	})
}

func main() {
	// Cargar .env
	err := godotenv.Load()
	if err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Recargar variables después de godotenv
	InstanceURL = os.Getenv("SALESFORCE_INSTANCE_URL")
	AccessToken = os.Getenv("SALESFORCE_ACCESS_TOKEN")

	http.HandleFunc("/api/submit", handleLead)
	http.HandleFunc("/health", handleHealth)
	fmt.Println("Middleware Go corriendo en puerto 8080...")
	http.ListenAndServe(":8080", nil)
}
