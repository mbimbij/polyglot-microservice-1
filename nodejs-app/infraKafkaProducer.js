// imports
const { v4: uuidv4 } = require('uuid');
const { Kafka } = require("kafkajs")

// constants
const clientId = process.env.CLIENT_ID
const brokers = process.env.BROKERS.split(",")
const topic = process.env.TOPIC

if(!clientId){
  console.log("clientId is null or undefined")
  process.exit(1)
}
if(!brokers){
  console.log("brokers is null or undefined")
  process.exit(1)
}
if(!topic){
  console.log("topic is null or undefined")
  process.exit(1)
}

console.log("clientId: "+clientId)
console.log("brokers: "+brokers)
console.log("topic: "+topic)

const kafka = new Kafka({ clientId, brokers })
const producer = kafka.producer()
producer.connect()

module.exports = {
  sendNotification: function(){
    var callId = uuidv4()
    var kafkaMessage = "new message " + callId
    producer.send({
        topic,
        messages: [
          {
            key: null,
            value: kafkaMessage,
          },
        ],
      })
    return kafkaMessage
  }
}