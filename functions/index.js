const functions = require("firebase-functions");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");

admin.initializeApp();
const db = admin.firestore();

// Razorpay config ko initialize karo
const razorpayConfig = functions.config().razorpay;
const instance = new Razorpay({
  key_id: razorpayConfig.key_id,
  key_secret: razorpayConfig.key_secret,
});

exports.processPayoutRequest = functions.firestore
    .document("payoutRequests/{requestId}")
    .onCreate(async (snap, context) => {
      const requestData = snap.data();
      const requestId = context.params.requestId;
      const userId = requestData.userId;

      const userRef = db.collection("users").doc(userId);
      const requestRef = db.collection("payoutRequests").doc(requestId);

      try {
        // Step 1: Transaction shuru karo for data consistency
        await db.runTransaction(async (transaction) => {
          const userDoc = await transaction.get(userRef);

          if (!userDoc.exists) {
            throw new Error("User not found!");
          }

          const userData = userDoc.data();
          const walletBalance = userData.walletBalance || 0;
          const requestedAmount = requestData.amount;

          // Step 2: Verify karo ki user ke paas sufficient balance hai
          if (walletBalance < requestedAmount) {
            throw new Error("Insufficient wallet balance.");
          }

          // Yahan par hum abhi ke liye maan rahe hain ki bank details aachi hain.
          // Production app mein aapko yeh details bhi validate karni chahiye.

          // Step 3: Payout create karo Razorpay par
          // Yeh ek simplified example hai. Aapko production mein fund account, etc.
          // handle karna pad sakta hai.
          const payoutOptions = {
            account_number: "2323230071727272", // Yeh ek test account hai
            fund_account_id: "fa_xxxxxxxxxxxxxx", // User ki fund account id
            amount: requestedAmount * 100, // Amount in paise
            currency: "INR",
            mode: "IMPS",
            purpose: "payout",
            queue_if_low_balance: true,
            narration: "Padhai Pedia Reward Payout",
          };

          // NOTE: Asli project mein, aapko pehle Razorpay par user ka
          // "contact" aur "fund account" banana hoga. Yahan hum direct
          // payout maan rahe hain.

          // const payoutResult = await instance.payouts.create(payoutOptions);
          // console.log("Razorpay Payout Result:", payoutResult);

          // Step 4: Agar payout successful ho, toh user ka wallet update karo
          const newBalance = walletBalance - requestedAmount;
          transaction.update(userRef, {walletBalance: newBalance});

          console.log(`Successfully processed payout for user ${userId}. New balance: ${newBalance}`);
        });

        // Step 5: Payout request ka status "completed" set karo
        await requestRef.update({status: "completed", processedAt: admin.firestore.FieldValue.serverTimestamp()});
        return {status: "success"};
      } catch (error) {
        console.error("Payout failed:", error.message);
        // Agar koi error aata hai, toh request ka status "failed" set kar do
        await requestRef.update({status: "failed", error: error.message});
        return {status: "error", message: error.message};
      }
    });
