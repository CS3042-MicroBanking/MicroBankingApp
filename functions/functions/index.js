/* eslint-disable linebreak-style */
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp(functions.config().functions);

exports.statusTrigger = functions.database.ref("/status")
    .onUpdate((change, context) => {
      const after = String(change.after.val());
      // const tokens = [];

      const db = admin.database();
      const ref = db.ref("/DeviceTokens/");


      ref.once("value").then(function(allData) {
        allData.forEach(function(deviceToken) {
          const token = deviceToken.child("token").val();
          console.log("Device: " + token);
          const message = {
            data: {message: after},
            token: token,
          };
          admin.messaging().send(message).then((response) => {
            console.log("message sent successfully: ", response);
          }).catch((error) => {
            console.log("Error sending message:", error);
          });
        });
      });
      return null;
    });
