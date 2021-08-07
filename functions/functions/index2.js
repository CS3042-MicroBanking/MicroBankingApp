const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp(functions.config().functions);

exports.statusTrigger = functions.database.ref("/status")
    .onUpdate((change, context) => {
      const after = String(change.after.val());
      const payload = {data: {message: after}};
      const tokens = [];

      const db = admin.database();
      const ref = db.ref("/DeviceTokens/");


      ref.once("value").then(function(allData) {
        allData.forEach(function(deviceToken) {
          console.log("Device: " + deviceToken.child("token").val());
          tokens.push(deviceToken.child("token").val());
        });
        try {
          admin.messaging().sendToDevice(tokens, payload);
          console.log("Message sent successfully");
        } catch (err) {
          console.log("Error sending notification: " + err);
        }
      });
      return null;
    });
