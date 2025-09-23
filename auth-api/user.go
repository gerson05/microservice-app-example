package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	jwt "github.com/dgrijalva/jwt-go"
	"github.com/sony/gobreaker"
)

var allowedUserHashes = map[string]interface{}{
	"admin_admin": nil,
	"johnd_foo":   nil,
	"janed_ddd":   nil,
}

type User struct {
	Username  string `json:"username"`
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
	Role      string `json:"role"`
}

type HTTPDoer interface {
	Do(req *http.Request) (*http.Response, error)
}

type UserService struct {
	Client            HTTPDoer
	UserAPIAddress    string
	AllowedUserHashes map[string]interface{}
	cb                *gobreaker.CircuitBreaker
}

// Login con Circuit Breaker
func (h *UserService) Login(ctx context.Context, username, password string) (User, error) {
	user, err := h.getUser(ctx, username)
	if err != nil {
		return user, err
	}

	userKey := fmt.Sprintf("%s_%s", username, password)
	if _, ok := h.AllowedUserHashes[userKey]; !ok {
		return user, ErrWrongCredentials
	}

	return user, nil
}

// getUser con Circuit Breaker
func (h *UserService) getUser(ctx context.Context, username string) (User, error) {
	var user User

	// Construir la request
	token, err := h.getUserAPIToken(username)
	if err != nil {
		return user, err
	}

	url := fmt.Sprintf("%s/users/%s", h.UserAPIAddress, username)
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Add("Authorization", "Bearer "+token)
	req = req.WithContext(ctx)

	// Ejecutar dentro del breaker
	result, err := h.cb.Execute(func() (interface{}, error) {
		resp, err := h.Client.Do(req)
		if err != nil {
			fmt.Println("Circuit breaker error:", err)
			return user, fmt.Errorf("breaker triggered: %w", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			bodyBytes, _ := ioutil.ReadAll(resp.Body)
			return nil, fmt.Errorf("user API error (%d): %s", resp.StatusCode, string(bodyBytes))
		}

		var u User
		if err := json.NewDecoder(resp.Body).Decode(&u); err != nil {
			return nil, fmt.Errorf("error decoding user: %w", err)
		}
		return u, nil
	})

	// Si el breaker está abierto o hay error en la ejecución
	if err != nil {
		// Aquí puedes loggear que el circuito está abierto
		return user, fmt.Errorf("breaker triggered: %w", err)
	}

	// Verificamos el tipo de resultado
	switch val := result.(type) {
	case User:
		return val, nil
	default:
		return user, fmt.Errorf("unexpected breaker result type: %T", val)
	}
}


func (h *UserService) getUserAPIToken(username string) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)
	claims := token.Claims.(jwt.MapClaims)
	claims["username"] = username
	claims["scope"] = "read"
	return token.SignedString([]byte(jwtSecret))
}
