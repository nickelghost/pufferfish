package main

import (
	"bytes"
	"embed"
	"fmt"
	"html/template"
	"io/fs"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog/log"
	"github.com/tdewolff/minify"
	"github.com/tdewolff/minify/html"
)

//go:embed templates
var templatesFS embed.FS

//go:embed public
var publicFS embed.FS

type pufferfish struct {
	ID           string
	Name         string
	BinomialName string
	ImageURL     string
	MaxLength    float64
}

var pufferfishList = []pufferfish{
	{
		ID:           "dwarf-pufferfish",
		Name:         "Dwarf Pufferfish",
		BinomialName: "Carinotetraodon travancoricus",
		ImageURL:     "/images/dwarf-pufferfish.jpg",
		MaxLength:    3.5, //nolint:gomnd
	},
	{
		ID:           "ocellated-pufferfish",
		Name:         "Ocellated Pufferfish",
		BinomialName: "Leiodon cutcutia",
		ImageURL:     "/images/ocellated-pufferfish.jpg",
		MaxLength:    15, //nolint:gomnd
	},
	{
		ID:           "silver-cheeked-toadfish",
		Name:         "Silver-cheeked Toadfish",
		BinomialName: "Lagocephalus sceleratus",
		ImageURL:     "/images/silver-cheeked-toadfish.jpg",
		MaxLength:    110, //nolint:gomnd
	},
}

func renderTemplate(name string, data any) (string, error) {
	tpl, err := template.ParseFS(
		templatesFS,
		"templates/layout.html",
		fmt.Sprintf("templates/%s.html", name),
	)
	if err != nil {
		return "", fmt.Errorf("parse template fs: %w", err)
	}

	var buff bytes.Buffer

	err = tpl.Execute(&buff, data)
	if err != nil {
		return "", fmt.Errorf("execute template: %w", err)
	}

	m := minify.New()
	htmlm := html.Minifier{ //nolint:exhaustruct
		KeepEndTags:      true,
		KeepDocumentTags: true,
	}
	m.AddFunc("text/html", htmlm.Minify)

	minTpl, err := m.String("text/html", buff.String())
	if err != nil {
		return "", fmt.Errorf("minify html: %w", err)
	}

	return minTpl, nil
}

type Handlers struct {
	BackgroundColor string
}

func (h Handlers) indexHandler(w http.ResponseWriter, r *http.Request) {
	tpl, err := renderTemplate("index", map[string]any{
		"PufferfishList":  pufferfishList,
		"BackgroundColor": h.BackgroundColor,
	})
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		log.Err(err).Msg("error")

		return
	}

	if _, err := w.Write([]byte(tpl)); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		log.Err(err).Msg("error")

		return
	}
}

func (h Handlers) pufferfishHandler(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	requestedPufferfish := pufferfish{} //nolint:exhaustruct
	pufferfishFound := false

	for _, p := range pufferfishList {
		if p.ID == id {
			requestedPufferfish = p
			pufferfishFound = true

			break
		}
	}

	if !pufferfishFound {
		w.WriteHeader(http.StatusNotFound)
		log.Warn().Msg("not_found")

		return
	}

	tpl, err := renderTemplate("pufferfish", map[string]any{
		"Pufferfish":      requestedPufferfish,
		"BackgroundColor": h.BackgroundColor,
	})
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		log.Err(err).Msg("error")

		return
	}

	if _, err := w.Write([]byte(tpl)); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		log.Err(err).Msg("error")

		return
	}
}

func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Info().
			Str("source", r.RemoteAddr).
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Dur("duration", time.Since(start)).
			Msg("req_completed")
	})
}

func run() error {
	// set up public fs
	pFS, err := fs.Sub(publicFS, "public")
	if err != nil {
		return fmt.Errorf("public fs sub: %w", err)
	}

	// set up handlers
	h := Handlers{BackgroundColor: "white"}
	if bgColor := os.Getenv("APP_BACKGROUND_COLOR"); bgColor != "" {
		h.BackgroundColor = bgColor
	}

	// set up router
	r := chi.NewRouter()
	r.Use(LoggingMiddleware)
	r.Use(middleware.Heartbeat("/health"))
	r.Handle("/*", http.FileServer(http.FS(pFS)))
	r.Get("/", h.indexHandler)
	r.Get("/{id}", h.pufferfishHandler)

	// server
	s := http.Server{ //nolint:exhaustruct
		Addr:              ":8080",
		Handler:           r,
		ReadHeaderTimeout: time.Second,
	}
	if err := s.ListenAndServe(); err != nil {
		return fmt.Errorf("listen and serve: %w", err)
	}

	return nil
}

func main() {
	if err := run(); err != nil {
		log.Fatal().Err(err).Msg("run_failed")
	}
}
