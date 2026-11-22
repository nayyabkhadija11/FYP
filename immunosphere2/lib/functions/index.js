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
// Helper: notify a parent identified by CNIC.
// 1) Pehle in-app notification (notifications collection) save hoti hai,
//    taake push fail bhi ho jaye to app ke andar list me zaroor dikhe.
// 2) Phir users/{uid}.fcmToken par push bheji jati hai.
//    users.cnic dashes ke bina aur dashes ke sath, dono format dhoondhe jate hain.
// extra: optional additional fields (jaise type / childId) jo
//        notification doc me save honge.
// -----------------------------------------------------------------
async function sendNotificationToCnic(cnic, title, body, extra = {}) {
  if (!cnic) return;
  const cleanCnic = cnic.toString().replace(/-/g, "").trim();
  if (!cleanCnic) return;

  // 1. In-app notification
  await db.collection("notifications").add({
    parentCNIC: cleanCnic,
    title,
    message: body,
    time: "Just now",
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    ...extra,
  });

  // 2. Push notification
  try {
    const variants = [cleanCnic];
    if (cleanCnic.length === 13) {
      variants.push(`${cleanCnic.slice(0, 5)}-${cleanCnic.slice(5, 12)}-${cleanCnic.slice(12)}`);
    }

    const usersSnap = await db.collection("users").where("cnic", "in", variants).get();
    const tokens = new Set();
    usersSnap.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token) tokens.add(token);
    });

    if (tokens.size > 0) {
      await messaging.sendEachForMulticast({
        tokens: Array.from(tokens),
        notification: { title, body },
      });
    } else {
      console.log(`No FCM token found for CNIC ${cleanCnic}`);
    }
  } catch (e) {
    console.error(`Push failed for CNIC ${cleanCnic}:`, e);
  }
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
// 3B. TRIGGER: Campaign visit result recorded (Polio / Sub National Drive).
// Polio form (record_status_screen) sirf campaign_assignments update karta
// hai, vaccinations me nahi likhta -- isliye uska notification yahan se jata
// hai. Routine Immunization form fingerMark = "N/A" set karta hai aur woh
// vaccinations me bhi likhta hai (jis se trigger #2 already notify kar deta
// hai), is liye Vaccinated/Refused par routine form ko skip kiya hai taake
// double notification na ho. "Missed" routine me bhi sirf assignment me jata
// hai, is liye woh dono forms ke liye notify hota hai.
// -----------------------------------------------------------------
exports.onCampaignAssignmentUpdated = functions.firestore
  .document("campaign_assignments/{assignmentId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === after.status) return;

    const status = (after.status || "").toString().toLowerCase();
    if (!["vaccinated", "refused", "missed"].includes(status)) return;

    const isRoutineForm = after.fingerMark === "N/A";
    if (status !== "missed" && isRoutineForm) return;

    const childId = after.childId;
    if (!childId) return;

    const childDoc = await db.collection("children").doc(childId).get();
    if (!childDoc.exists) return;

    const childData = childDoc.data();
    const childName = childData.fullName || childData.name || "Your child";
    const cnic = childData.cnic;
    const vaccine = after.vaccineGiven && after.vaccineGiven !== "None" ? after.vaccineGiven : "the vaccine";
    const reason = after.statusReason || "not available";

    let title;
    let body;
    if (status === "vaccinated") {
      title = "Vaccine Administered";
      body = `${childName} has received ${vaccine} in the campaign.`;
    } else if (status === "refused") {
      title = "Vaccine Refused";
      body = `Campaign vaccination was marked as refused for ${childName}.`;
    } else {
      title = "Vaccine Missed";
      body = `The vaccinator visited but ${childName} could not be vaccinated (${reason}). Please visit your nearest BHU center.`;
    }

    await sendNotificationToCnic(cnic, title, body);
  });

// -----------------------------------------------------------------
// 4. SCHEDULED: Daily check for newly-missed doses.
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
// 4B. SCHEDULED: Daily due-date reminder.
// Roz subah 9 baje (Pakistan time). Jis bache ki koi EPI vaccine ki
// date aa chuki hai aur abhi tak lagi nahi, uske parent ko roz ek
// reminder jati hai (us bache ki saari pending vaccines ek message me).
// Vaccine lagte hi (vaccinations me record ban'ne par) reminder band.
// Purani reminder delete ho kar nayi aati hai taake list me dher na lage.
// -----------------------------------------------------------------
exports.sendDueVaccineReminders = functions
  .runWith({ timeoutSeconds: 300 })
  .pubsub.schedule("0 9 * * *")
  .timeZone("Asia/Karachi")
  .onRun(async () => {
    const now = new Date();
    const DAY_MS = 24 * 60 * 60 * 1000;
    const childrenSnap = await db.collection("children").get();

    for (const childDoc of childrenSnap.docs) {
      try {
        const childData = childDoc.data();
        const rawDob = childData.dob || childData.dateOfBirth;
        if (!rawDob) continue; // dob nahi to schedule nahi ban sakta

        const cnic = childData.cnic;
        if (!cnic) continue;

        const childName = childData.fullName || childData.name || "Your child";
        const dob = parseDob(rawDob);

        const vaxSnap = await db
          .collection("vaccinations")
          .where("childId", "==", childDoc.id)
          .get();

        // Sirf wo records "given" maane jayenge jo refused nahi hain
        const givenNorms = vaxSnap.docs
          .filter((d) => (d.data().status || "").toString().toLowerCase() !== "refused")
          .map((d) => normalize((d.data().vaccineName || "").toString()));

        const pending = [];
        let earliestDue = null;

        for (const stage of generateEpiSchedule(dob)) {
          if (stage.dueDate > now) continue; // abhi date nahi aayi

          for (const vaccine of stage.vaccines) {
            const targetNorm = normalize(vaccine);
            const isGiven = givenNorms.some(
              (s) => s && (s === targetNorm || s.includes(targetNorm) || targetNorm.includes(s))
            );
            if (isGiven) continue;

            pending.push(vaccine);
            if (!earliestDue || stage.dueDate < earliestDue) earliestDue = stage.dueDate;
          }
        }

        if (pending.length === 0) continue;

        const dueStr = earliestDue.toLocaleDateString("en-GB", {
          day: "2-digit",
          month: "short",
          year: "numeric",
          timeZone: "Asia/Karachi",
        });
        const daysLate = Math.floor((now.getTime() - earliestDue.getTime()) / DAY_MS);

        const body =
          daysLate <= 0
            ? `${childName}'s vaccination date is today (${dueStr}). Due: ${pending.join(", ")}. Please visit your nearest BHU center.`
            : `${childName}'s vaccination date was ${dueStr}. Still pending: ${pending.join(", ")}. Please get them vaccinated at your nearest BHU center.`;

        // Is bache ki pichli reminder(s) delete karo
        const cleanCnic = cnic.toString().replace(/-/g, "").trim();
        const oldSnap = await db
          .collection("notifications")
          .where("parentCNIC", "==", cleanCnic)
          .where("childId", "==", childDoc.id)
          .where("type", "==", "reminder")
          .get();
        if (!oldSnap.empty) {
          const batch = db.batch();
          oldSnap.docs.forEach((d) => batch.delete(d.ref));
          await batch.commit();
        }

        await sendNotificationToCnic(cnic, "Vaccine Due Reminder", body, {
          type: "reminder",
          childId: childDoc.id,
        });
      } catch (e) {
        console.error(`Reminder failed for child ${childDoc.id}:`, e);
      }
    }

    return null;
  });

// -----------------------------------------------------------------
// 5. SCHEDULED: Daily cleanup of notifications older than 30 days.
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