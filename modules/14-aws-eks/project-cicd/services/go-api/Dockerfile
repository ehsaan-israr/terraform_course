FROM golang:1.22-alpine AS builder

WORKDIR /src
COPY go.mod ./
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/go-api .

FROM gcr.io/distroless/static-debian12
COPY --from=builder /bin/go-api /go-api
EXPOSE 8080
ENTRYPOINT ["/go-api"]
