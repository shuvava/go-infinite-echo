FROM golang:1.16.2-buster@sha256:5a6302e91acb152050d661c9a081a535978c629225225ed91a8b979ad24aafcd as build

ENV GOOS=linux \
    GOARCH=amd64

RUN set -ex \
    && DEBIAN_FRONTEND=noninteractive \
    && apt update \
    && apt upgrade -y --no-install-recommends \
    && apt install -y --no-install-recommends build-essential \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.39.0

# Move to working directory /build
WORKDIR /build

COPY go.* ./
RUN go mod download \
    && go mod verify

# Copy the code into the container
COPY . .

# Build the application
RUN set -ex \
    && go fmt \
    && golangci-lint run -v \
    && CGO_ENABLED=0 go build -ldflags="-w -s" -o main .

# Move to /dist directory as the place for resulting binary folder
WORKDIR /dist

# Copy binary from build to main folder
RUN cp /build/main .

FROM gcr.io/distroless/static-debian10:nonroot@sha256:9023a3c8ebb0c46aef1f6f2819ce867f90bb9570a3c2438ae067f45b7cd75675

WORKDIR /app

COPY --from=build --chown=nonroot:nonroot /dist/main .

USER nonroot:nonroot

# Command to run
ENTRYPOINT ["/app/main"]
