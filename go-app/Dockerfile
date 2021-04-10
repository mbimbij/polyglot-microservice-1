FROM golang:1.16-alpine AS build
ENV CGO_ENABLED=1
ENV GO111MODULE=auto
#Install git
RUN apk add --no-cache git
RUN apk add build-base
RUN apk add librdkafka-dev
COPY *.go .
#Get the hello world package from a GitHub repository
RUN go get -tags musl gopkg.in/confluentinc/confluent-kafka-go.v1/kafka
# Build the project and send the output to /bin/HelloWorld
RUN ls
RUN go build -tags musl -o /go-app

FROM golang:1.16-alpine
#Copy the build's output binary from the previous build container
COPY --from=build /go-app /go-app
ENTRYPOINT ["/go-app"]