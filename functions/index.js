// This goes in your Firebase Cloud Functions (index.js)
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Cloud Function to send FCM notifications when a new notification document is created
exports.sendBlockNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();

        // Check if this is a block notification
        if (notification.data && notification.data.type === 'account_blocked') {
            const userId = notification.userId;
            const fcmToken = notification.fcmToken;

            if (!fcmToken) {
                console.log('No FCM token found for user:', userId);
                return null;
            }

            // Create the message payload
            const message = {
                token: fcmToken,
                notification: {
                    title: notification.title,
                    body: notification.body,
                },
                data: {
                    type: notification.data.type,
                    forceLogout: notification.data.forceLogout ? 'true' : 'false',
                    userId: userId,
                },
                // High priority to ensure immediate delivery
                android: {
                    priority: 'high',
                },
                apns: {
                    headers: {
                        'apns-priority': '10',
                    },
                },
            };

            try {
                // Send the message
                const response = await admin.messaging().send(message);
                console.log('Block notification sent successfully:', response);

                // Update the notification document to mark it as sent
                await snap.ref.update({
                    sent: true,
                    sentAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                return response;
            } catch (error) {
                console.error('Error sending block notification:', error);

                // Update the notification document to mark the error
                await snap.ref.update({
                    sent: false,
                    error: error.message,
                });

                return null;
            }
        }

        return null;
    });