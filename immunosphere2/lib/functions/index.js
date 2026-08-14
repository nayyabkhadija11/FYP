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
  });