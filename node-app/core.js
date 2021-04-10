// imports
const { v4: uuidv4 } = require('uuid');
const eventProducer = require('./infraKafkaProducer.js');

// constants
const instanceId = uuidv4();

module.exports = {
  handleRequest: function(){
    var kafkaMessage = eventProducer.sendNotification()
    return 'Hello nodeJS - v4 - '+instanceId+'. Sent '+kafkaMessage
  }
}