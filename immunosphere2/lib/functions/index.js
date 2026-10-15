/*const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// -----------------------------------------------------------------
// SAME EPI SCHEDULE AS lib/helpers/epi_schedule_helper.dart
// Kept in sync manually -- if the Dart schedule ever changes,
// update this list too.
// -----------------------------------------------------------------
function generateEpiSchedule(dob) {
  const addDays = (date, days) => new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
  return [
    { stage: "At Birth (Within 24 Hours)", dueDate: dob, vaccines: ["BCG", "OPV-0"] },
    { stage: "6 Weeks", dueDate: addDays(dob, 42), vaccines: ["Pentavalent-1", "PCV-1", "OPV-1", "Rotavirus-1"] },
    { stage: "10 Weeks", dueDate: addDays(dob, 70), vaccines: ["Pentavalent-2", "PCV-2", "OPV-2", "Rotavirus-2"] },
    { stage: "14 Weeks", dueDate: addDays(dob, 98), vaccines: ["Pentavalent-3", "PCV-3", "OPV-3", "IPV-1"] },
    { stage: "9 Months", dueDate: addDays(dob, 270), vaccines: ["Measles-Rubella (MR-1)", "TCV"] },
    { stage: "15 Months", dueDate: addDays(dob, 450), vaccines: ["Measles-Rubella (MR-2)", "IPV-2"] },
  ];
}

function normalize(name) {
  return (name || "").toLowerCase().replace(/[^a-z0-9]/g, "");
}

function parseDob(val) {
  if (val && typeof val.toDate === "function") return val.toDate(); // Firestore Timestamp
  if (val instanceof Date) return val;
  if (typeof val === "string" && val.trim()) {
    const d = new Date(val);
    if (!isNaN(d.getTime())) return d;
  }
  return new Date();
}

// -----------------------------------------------------------------
// Helper: send a notification to a parent identified by CNIC.
// Looks up users/{uid} docs where cnic == parentCnic and reads
// the fcmToken field saved by the Flutter app.
// -----------------------------------------------------------------
async function sendNotificationToCnic(cnic, title, body) {
  if (!cnic) return;
  const cleanCnic = cnic.toString().replace(/-/g, "").trim();

  const usersSnap = await db.collection("users").where("cnic", "==", cleanCnic).get();
  const tokens = [];
  usersSnap.forEach((doc) => {
    const token = doc.data().fcmToken;
    if (token) tokens.push(token);
  });

  if (tokens.length === 0) {
    console.log(`No FCM token found for CNIC ${cleanCnic}`);
    return;
  }

  await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
  });

  // Also save it into the notifications collection so it shows in the
  // in-app "Recent Notifications" list (parent_home_screen.dart already
  // reads from here).
  await db.collection("notifications").add({
    parentCNIC: cleanCnic,
    title,
    message: body,
    time: "Just now",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// -----------------------------------------------------------------
// 1. TRIGGER: New child registered
// -----------------------------------------------------------------
exports.onChildRegistered = functions.firestore
  .document("children/{childId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const childName = data.fullName || data.name || "Your child";
    const cnic = data.cnic;

    await sendNotificationToCnic(
      cnic,
      "Child Registered",
      `${childName} has been successfully registered for vaccination tracking.`
    );
  });

// -----------------------------------------------------------------
// 2. TRIGGER: Vaccine dose recorded (given / refused)
// -----------------------------------------------------------------
exports.onVaccinationRecorded = functions.firestore
  .document("vaccinations/{vaxId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const childId = data.childId;
    const vaccineName = data.vaccineName || "a vaccine";
    const status = (data.status || "vaccinated").toLowerCase();

    if (!childId) return;

    const childDoc = await db.collection("children").doc(childId).get();
    if (!childDoc.exists) return;

    const childData = childDoc.data();
    const childName = childData.fullName || childData.name || "Your child";
    const cnic = childData.cnic;

    let title;
    let body;
    if (status === "refused") {
      title = "Vaccine Refused";
      body = `${vaccineName} was marked as refused for ${childName}.`;
    } else if (status === "missed") {
      title = "Vaccine Missed";
      body = `${vaccineName} was marked as missed for ${childName}.`;
    } else {
      title = "Vaccine Administered";
      body = `${childName} has received the ${vaccineName} dose.`;
    }

    await sendNotificationToCnic(cnic, title, body);
  });

// -----------------------------------------------------------------
// 3. SCHEDULED: Daily check for newly-missed doses.
// "Missed" isn't a document write -- it's just 14+ days passing
// with no matching vaccination record -- so it has to be checked
// on a timer instead of a trigger. Runs once every 24 hours.
// Keeps a 'notifiedMissedVaccines' array on each child doc so the
// same missed dose isn't notified twice.
// -----------------------------------------------------------------
exports.checkMissedVaccines = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const now = new Date();
    const childrenSnap = await db.collection("children").get();

    for (const childDoc of childrenSnap.docs) {
      const childData = childDoc.data();
      const childId = childDoc.id;
      const childName = childData.fullName || childData.name || "Child";
      const cnic = childData.cnic;
      const dob = parseDob(childData.dob || childData.dateOfBirth);

      const alreadyNotified = new Set(childData.notifiedMissedVaccines || []);

      const vaxSnap = await db
        .collection("vaccinations")
        .where("childId", "==", childId)
        .get();
      const givenRecords = vaxSnap.docs.map((d) => ({
        vaccineName: (d.data().vaccineName || "").toString(),
      }));

      const schedule = generateEpiSchedule(dob);
      const newlyMissed = [];

      for (const stage of schedule) {
        const dueDate = stage.dueDate;
        for (const vaccine of stage.vaccines) {
          if (alreadyNotified.has(vaccine)) continue;

          const targetNorm = normalize(vaccine);
          const isGiven = givenRecords.some((r) => {
            const storedNorm = normalize(r.vaccineName);
            return (
              storedNorm === targetNorm ||
              storedNorm.includes(targetNorm) ||
              targetNorm.includes(storedNorm)
            );
          });
          if (isGiven) continue;

          const gracePeriodEnd = new Date(dueDate.getTime() + 14 * 24 * 60 * 60 * 1000);
          if (now > gracePeriodEnd) {
            newlyMissed.push(vaccine);
          }
        }
      }

      if (newlyMissed.length > 0) {
        for (const vaccine of newlyMissed) {
          await sendNotificationToCnic(
            cnic,
            "Vaccine Missed",
            `${childName} has missed the ${vaccine} dose. Please visit your nearest BHU center.`
          );
        }

        await childDoc.ref.update({
          notifiedMissedVaccines: admin.firestore.FieldValue.arrayUnion(...newlyMissed),
        });
      }
    }

    return null;
  }); */
  const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// -----------------------------------------------------------------
// SAME EPI SCHEDULE AS lib/helpers/epi_schedule_helper.dart
// Kept in sync manually -- if the Dart schedule ever changes,
// update this list too.
// -----------------------------------------------------------------
function generateEpiSchedule(dob) {
  const addDays = (date, days) => new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
  return [
    { stage: "At Birth (Within 24 Hours)", dueDate: dob, vaccines: ["BCG", "OPV-0"] },
    { stage: "6 Weeks", dueDate: addDays(dob, 42), vaccines: ["Pentavalent-1", "PCV-1", "OPV-1", "Rotavirus-1"] },
    { stage: "10 Weeks", dueDate: addDays(dob, 70), vaccines: ["Pentavalent-2", "PCV-2", "OPV-2", "Rotavirus-2"] },
    { stage: "14 Weeks", dueDate: addDays(dob, 98), vaccines: ["Pentavalent-3", "PCV-3", "OPV-3", "IPV-1"] },
    { stage: "9 Months", dueDate: addDays(dob, 270), vaccines: ["Measles-Rubella (MR-1)", "TCV"] },
    { stage: "15 Months", dueDate: addDays(dob, 450), vaccines: ["Measles-Rubella (MR-2)", "IPV-2"] },
  ];
}

function normalize(name) {
  return (name || "").toLowerCase().replace(/[^a-z0-9]/g, "");
}

function parseDob(val) {
  if (val && typeof val.toDate === "function") return val.toDate(); // Firestore Timestamp
  if (val instanceof Date) return val;
  if (typeof val === "string" && val.trim()) {
    const d = new Date(val);
    if (!isNaN(d.getTime())) return d;
  }
  return new Date();
}

// -----------------------------------------------------------------
// Helper: send a notification to a parent identified by CNIC.
// Looks up users/{uid} docs where cnic == parentCnic and reads
// the fcmToken field saved by the Flutter app.
// -----------------------------------------------------------------
async function sendNotificationToCnic(cnic, title, body) {
  if (!cnic) return;
  const cleanCnic = cnic.toString().replace(/-/g, "").trim();

  const usersSnap = await db.collection("users").where("cnic", "==", cleanCnic).get();
  const tokens = [];
  usersSnap.forEach((doc) => {
    const token = doc.data().fcmToken;
    if (token) tokens.push(token);
  });

  if (tokens.length > 0) {
    await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
    });
  } else {
    console.log(`No FCM token found for CNIC ${cleanCnic}`);
  }

  // Also save it into the notifications collection so it shows in the
  // in-app "Recent Notifications" / Notification Center list.
  // isRead starts false -- the Flutter app flips this to true when the
  // parent opens/taps the notification, which is what drives the
  // unread-count badge on the home screen bell icon.
  await db.collection("notifications").add({
    parentCNIC: cleanCnic,
    title,
    message: body,
    time: "Just now",
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// -----------------------------------------------------------------
// 1. TRIGGER: New child registered
// -----------------------------------------------------------------
exports.onChildRegistered = functions.firestore
  .document("children/{childId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const childName = data.fullName || data.name || "Your child";
    const cnic = data.cnic;

    await sendNotificationToCnic(
      cnic,
      "Child Registered",
      `${childName} has been successfully registered for vaccination tracking.`
    );
  });

// -----------------------------------------------------------------
// 2. TRIGGER: Vaccine dose recorded (given / refused)
// -----------------------------------------------------------------
exports.onVaccinationRecorded = functions.firestore
  .document("vaccinations/{vaxId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const childId = data.childId;
    const vaccineName = data.vaccineName || "a vaccine";
    const status = (data.status || "vaccinated").toLowerCase();

    if (!childId) return;

    const childDoc = await db.collection("children").doc(childId).get();
    if (!childDoc.exists) return;

    const childData = childDoc.data();
    const childName = childData.fullName || childData.name || "Your child";
    const cnic = childData.cnic;

    let title;
    let body;
    if (status === "refused") {
      title = "Vaccine Refused";
      body = `${vaccineName} was marked as refused for ${childName}.`;
    } else if (status === "missed") {
      title = "Vaccine Missed";
      body = `${vaccineName} was marked as missed for ${childName}.`;
    } else {
      title = "Vaccine Administered";
      body = `${childName} has received the ${vaccineName} dose.`;
    }

    await sendNotificationToCnic(cnic, title, body);
  });

// -----------------------------------------------------------------
// 3. TRIGGER: Child assigned to a campaign (e.g. Polio drive).
// This fires once per child -- createCampaign() in campaign_service.dart
// writes one campaign_assignments doc per child when a supervisor
// creates a campaign, so this is the most precise point to notify
// exactly the parents whose children are actually included.
// -----------------------------------------------------------------
exports.onCampaignAssignmentCreated = functions.firestore
  .document("campaign_assignments/{assignmentId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const campaignId = data.campaignId;
    const childId = data.childId;
    if (!campaignId || !childId) return;

    const [campaignDoc, childDoc] = await Promise.all([
      db.collection("campaigns").doc(campaignId).get(),
      db.collection("children").doc(childId).get(),
    ]);
    if (!campaignDoc.exists || !childDoc.exists) return;

    const campaign = campaignDoc.data();
    const childData = childDoc.data();
    const cnic = childData.cnic;
    const childName = childData.fullName || childData.name || "Your child";
    const campaignName = campaign.name || "A vaccination campaign";
    const areas = Array.isArray(campaign.targetAreas) && campaign.targetAreas.length > 0
      ? campaign.targetAreas.join(", ")
      : "your area";

    let dateStr = "soon";
    if (campaign.startDate && typeof campaign.startDate.toDate === "function") {
      const d = campaign.startDate.toDate();
      dateStr = d.toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
    }

    await sendNotificationToCnic(
      cnic,
      campaignName,
      `${campaignName} will start on ${dateStr} in ${areas}. ${childName} is included in this campaign.`
    );
  });

// -----------------------------------------------------------------
// 4. SCHEDULED: Daily check for newly-missed doses.
// "Missed" isn't a document write -- it's just 14+ days passing
// with no matching vaccination record -- so it has to be checked
// on a timer instead of a trigger. Runs once every 24 hours.
// Keeps a 'notifiedMissedVaccines' array on each child doc so the
// same missed dose isn't notified twice.
// -----------------------------------------------------------------
exports.checkMissedVaccines = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const now = new Date();
    const childrenSnap = await db.collection("children").get();

    for (const childDoc of childrenSnap.docs) {
      const childData = childDoc.data();
      const childId = childDoc.id;
      const childName = childData.fullName || childData.name || "Child";
      const cnic = childData.cnic;
      const dob = parseDob(childData.dob || childData.dateOfBirth);

      const alreadyNotified = new Set(childData.notifiedMissedVaccines || []);

      const vaxSnap = await db
        .collection("vaccinations")
        .where("childId", "==", childId)
        .get();
      const givenRecords = vaxSnap.docs.map((d) => ({
        vaccineName: (d.data().vaccineName || "").toString(),
      }));

      const schedule = generateEpiSchedule(dob);
      const newlyMissed = [];

      for (const stage of schedule) {
        const dueDate = stage.dueDate;
        for (const vaccine of stage.vaccines) {
          if (alreadyNotified.has(vaccine)) continue;

          const targetNorm = normalize(vaccine);
          const isGiven = givenRecords.some((r) => {
            const storedNorm = normalize(r.vaccineName);
            return (
              storedNorm === targetNorm ||
              storedNorm.includes(targetNorm) ||
              targetNorm.includes(storedNorm)
            );
          });
          if (isGiven) continue;

          const gracePeriodEnd = new Date(dueDate.getTime() + 14 * 24 * 60 * 60 * 1000);
          if (now > gracePeriodEnd) {
            newlyMissed.push(vaccine);
          }
        }
      }

      if (newlyMissed.length > 0) {
        for (const vaccine of newlyMissed) {
          await sendNotificationToCnic(
            cnic,
            "Vaccine Missed",
            `${childName} has missed the ${vaccine} dose. Please visit your nearest BHU center.`
          );
        }

        await childDoc.ref.update({
          notifiedMissedVaccines: admin.firestore.FieldValue.arrayUnion(...newlyMissed),
        });
      }
    }

    return null;
  });

// -----------------------------------------------------------------
// 5. SCHEDULED: Daily cleanup of old notifications.
// Notifications older than 30 days are deleted so the collection
// doesn't grow forever and the Notification Center list doesn't
// fill up with stale alerts. Runs once every 24 hours, same
// schedule as the missed-vaccine check. Deletes in batches of 500
// (Firestore's batch-write limit) since a single run could have
// more than that to clear out.
// -----------------------------------------------------------------
exports.cleanupOldNotifications = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;
    const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - THIRTY_DAYS_MS);

    const oldNotifsSnap = await db
      .collection("notifications")
      .where("createdAt", "<", cutoff)
      .get();

    if (oldNotifsSnap.empty) return null;

    const docs = oldNotifsSnap.docs;
    for (let i = 0; i < docs.length; i += 500) {
      const batch = db.batch();
      const chunk = docs.slice(i, i + 500);
      chunk.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    console.log(`Deleted ${docs.length} notification(s) older than 30 days.`);
    return null;
  });