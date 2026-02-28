const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// This listens for new documents in your 'chemical test private' collection
exports.sendTestResultNotification = onDocumentCreated(
  "chemical test private/{recordId}",
  async (event) => {

    // In V2, the snapshot is accessed via event.data
    const snap = event.data;
    if (!snap) return null;

    const testData = snap.data();
    const requestedUserId = testData.requestedUserId;
    const testType = testData.testType;
    const predictionLabel = testData.predictionLabel;

    if (!requestedUserId) return null;

    try {
      // Look up the User's FCM Token from the 'users' collection
      const userDoc = await admin.firestore().collection("users").doc(requestedUserId).get();

      if (!userDoc.exists) return null;

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return null;

      // Construct the Push Notification
      const message = {
        notification: {
          title: "Lab Results Ready! 🔬",
          body: `The expert has finished your ${testType} test. Result: ${predictionLabel}. Tap to view details.`,
        },
        token: fcmToken,
      };

      // Send the push notification
      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
      return response;

    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  }
);