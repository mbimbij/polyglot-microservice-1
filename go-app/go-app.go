package main

import (
	"fmt"
	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
	"os"
)

func main() {

  bootstrapServers := os.Getenv("BROKERS")
  topic := os.Getenv("TOPIC")
  clientId := os.Getenv("CLIENT_ID")
  groupId := os.Getenv("GROUP_ID")

  fmt.Printf("bootstrapServers : %s\n",bootstrapServers )
  fmt.Printf("topic : %s\n",topic )
  fmt.Printf("clientId : %s\n",clientId )
  fmt.Printf("groupId : %s\n",groupId )

	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": bootstrapServers,
		"client.id":          clientId,
		"group.id":          groupId,
		"auto.offset.reset": "latest",
	})

	if err != nil {
		panic(err)
	}

// 	c.SubscribeTopics([]string{"test", "^aRegex.*[Tt]opic"}, nil)
  c.SubscribeTopics([]string{topic}, nil)

	for {
		msg, err := c.ReadMessage(-1)
		if err == nil {
			fmt.Printf("Message on %s: %s\n", msg.TopicPartition, string(msg.Value))
		} else {
			// The client will automatically try to recover from all errors.
			fmt.Printf("Consumer error: %v (%v)\n", err, msg)
		}
	}

	c.Close()
}