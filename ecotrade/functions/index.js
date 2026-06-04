/* eslint-disable */
"use strict";

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function: sendPushNotification
 *
 * Trigger: Setiap kali dokumen baru dibuat di koleksi `notifications/{notificationId}`.
 * Fungsi ini akan:
 * 1. Membaca recipientId, title, body, type, dan relatedId dari dokumen baru tersebut.
 * 2. Mengambil daftar fcmTokens milik user penerima dari koleksi `users`.
 * 3. Mengirim push notification ke semua perangkat terdaftar user tersebut via FCM.
 * 4. Membersihkan token yang sudah tidak valid/kedaluwarsa dari Firestore.
 */
exports.sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("Tidak ada data pada event.");
      return null;
    }

    const data = snapshot.data();
    const recipientId = data.recipientId;
    const title = data.title || "EcoTrade";
    const body = data.body || "Anda mempunyai notifikasi baru.";
    const type = data.type || "general";
    const relatedId = data.relatedId || "";

    if (!recipientId) {
      console.log("recipientId tidak ditemukan, notifikasi diabaikan.");
      return null;
    }

    try {
      // 1. Ambil dokumen user penerima untuk mendapatkan fcmTokens
      let tokens = []; // Array of objects: { token: string, userId: string }

      if (recipientId === "ADMIN_ALL") {
        const adminSnaps = await db
          .collection("users")
          .where("roles", "array-contains", "admin")
          .get();
          
        if (adminSnaps.empty) {
          console.log("Tidak ada user admin ditemukan. Push dilewati.");
          return null;
        }

        adminSnaps.forEach((doc) => {
          const userData = doc.data();
          if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
            userData.fcmTokens.forEach((t) => {
              tokens.push({ token: t, userId: doc.id });
            });
          }
        });
      } else {
        const userDoc = await db.collection("users").doc(recipientId).get();

        if (!userDoc.exists) {
          console.log(`User ${recipientId} tidak ditemukan di Firestore.`);
          return null;
        }

        const userData = userDoc.data();
        const userTokens = userData.fcmTokens || [];
        userTokens.forEach((t) => {
          tokens.push({ token: t, userId: recipientId });
        });
      }

      if (tokens.length === 0) {
        console.log(
          `User ${recipientId} tidak memiliki fcmToken terdaftar. Notifikasi push dilewati.`
        );
        return null;
      }

      const tokensArray = tokens.map((t) => t.token);
      console.log(
        `Mengirim notifikasi ke ${tokens.length} perangkat milik user ${recipientId}...`
      );

      // 2. Buat payload pesan FCM
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          // Data tambahan untuk navigasi saat notifikasi diklik
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: type,
          relatedId: relatedId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
            priority: "HIGH",
            defaultVibrateTimings: true,
          },
        },
        tokens: tokensArray,
      };

      // 3. Kirim notifikasi ke semua perangkat (multicast)
      const response = await admin.messaging().sendEachForMulticast(message);

      console.log(
        `Berhasil: ${response.successCount}, Gagal: ${response.failureCount}`
      );

      // 4. Bersihkan token yang sudah tidak valid
      if (response.failureCount > 0) {
        const tokensToRemove = [];

        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const errCode = resp.error ? resp.error.code : "";
            console.log(`Token [${idx}] gagal. Kode error: ${errCode}`);

            // Token tidak valid / sudah tidak terdaftar → hapus dari Firestore
            if (
              errCode === "messaging/invalid-registration-token" ||
              errCode === "messaging/registration-token-not-registered" ||
              errCode === "messaging/invalid-argument"
            ) {
              tokensToRemove.push(tokens[idx]);
            }
          }
        });

        if (tokensToRemove.length > 0) {
          console.log(`Menghapus token tidak valid...`);
          
          // Group tokens to remove by userId
          const tokensByUser = {};
          tokensToRemove.forEach(obj => {
            if (!tokensByUser[obj.userId]) tokensByUser[obj.userId] = [];
            tokensByUser[obj.userId].push(obj.token);
          });
          
          // Remove from each user
          for (const uid of Object.keys(tokensByUser)) {
             await db.collection("users").doc(uid).update({
               fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensByUser[uid]),
             });
          }
        }
      }

      return null;
    } catch (error) {
      console.error("Terjadi error saat mengirim notifikasi:", error);
      return null;
    }
  }
);
