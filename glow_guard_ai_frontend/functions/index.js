const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
    admin.initializeApp();
}

/**
 * 1. TRIGGER: New Expert Registration Email
 * Sends a welcome email when a new expert registers.
 */
exports.onExpertRegistered = onDocumentCreated("experts/{uid}", async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const expertData = snap.data();
    const expertEmail = expertData.email;
    const expertName = expertData.callingName;

    try {
        await admin.firestore().collection("mail").add({
            to: expertEmail,
            message: {
                subject: "GlowGuard AI: Application Received 🧪",
                html: `
                    <h3>Hello ${expertName},</h3>
                    <p>Thank you for registering as a Chemical Expert with GlowGuard AI.</p>
                    <p>Your application is currently <b>Pending Admin Verification</b>. Our team will review your uploaded credentials shortly.</p>
                    <p>You will receive another email once your account has been approved.</p>
                    <br>
                    <p>Best regards,<br>GlowGuard AI Team</p>
                `,
            },
        });
        console.log(`Welcome email queued for: ${expertEmail}`);
    } catch (error) {
        console.error("Error queueing welcome email:", error);
    }
    return null;
});

/**
 * 2. TRIGGER: Admin Approval/Rejection Email
 * Sends an update email when the expert's status field changes.
 */
exports.onExpertStatusUpdate = onDocumentUpdated("experts/{uid}", async (event) => {
    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();

    if (newValue.status === previousValue.status) return null;

    const expertEmail = newValue.email;
    const expertName = newValue.callingName;
    const newStatus = newValue.status;

    let subject = "";
    let htmlContent = "";

    if (newStatus === "active") {
        subject = "GlowGuard AI: Account Approved! 🎉";
        htmlContent = `
            <h3>Congratulations ${expertName}!</h3>
            <p>Your expert account has been <b>Approved</b>.</p>
            <p>You can now log in to the app and begin conducting chemical tests.</p>
            <br>
            <p>Best regards,<br>GlowGuard AI Team</p>
        `;
    } else if (newStatus === "rejected") {
        subject = "GlowGuard AI: Application Status Update";
        htmlContent = `
            <h3>Hello ${expertName},</h3>
            <p>Regrettably, your application has been <b>Rejected</b> at this time.</p>
            <p>If you believe this is an error, please contact our support team.</p>
            <br>
            <p>Best regards,<br>GlowGuard AI Team</p>
        `;
    } else {
        return null;
    }

    try {
        await admin.firestore().collection("mail").add({
            to: expertEmail,
            message: {
                subject: subject,
                html: htmlContent,
            },
        });
        console.log(`Status email queued for: ${expertEmail}`);
    } catch (error) {
        console.error("Error queueing status update email:", error);
    }
    return null;
});

/**
 * 3. TRIGGER: Lab Results Push Notification
 * Notifies the user when their chemical test results are ready.
 */
exports.sendTestResultNotification = onDocumentCreated(
  "chemical test private/{recordId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const testData = snap.data();
    const requestedUserId = testData.requestedUserId;
    const testType = testData.testType;
    const predictionLabel = testData.predictionLabel;

    if (!requestedUserId) return null;

    try {
      const userDoc = await admin.firestore().collection("users").doc(requestedUserId).get();
      if (!userDoc.exists) return null;

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return null;

      const message = {
        notification: {
          title: "Lab Results Ready! 🔬",
          body: `The expert has finished your ${testType} test. Result: ${predictionLabel}.`,
        },
        token: fcmToken,
      };

      const response = await admin.messaging().send(message);
      console.log("Successfully sent push notification:", response);
      return response;
    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  }
);