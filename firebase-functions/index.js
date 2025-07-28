/**
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
const admin = require("firebase-admin");
const {onRequest} = require("firebase-functions/v2/https");
const {
  onDocumentDeleted,
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");
const {getStorage, getDownloadURL} = require("firebase-admin/storage");
const {getFirestore} = require("firebase-admin/firestore");
const {logger} = require("firebase-functions");

if (!admin.apps.length) {
  admin.initializeApp();
} else {
  admin.app(); // Use the already initialized default app
}

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started?gen=2nd
// https://firebase.google.com/docs/storage/admin/start
// https://firebase.google.com/docs/reference/admin/node/firebase-admin.storage

exports.onSnapDeleted = onDocumentDeleted("snaps/{snapId}", (event) => {
  const snapshot = event.data;
  const data = snapshot.data();
  const bucket = getStorage().bucket();
  const file = bucket.file(data.fileRef);
  return file.delete().then(() => {
    logger.info(`Deleted file ${data.fileRef}`);
  });
});

const fetch = require("node-fetch");
const FormData = require("form-data");

async function transformImage(image, title="") {
  title = title.slice(0, 20);
  const formData = new FormData();
  formData.append("init_image", image);
  formData.append("init_image_mode", "IMAGE_STRENGTH");
  formData.append("image_strength", 0.45);
  formData.append("steps", 30);
  formData.append("seed", 0);
  formData.append("cfg_scale", 6);
  formData.append("samples", 1);
  formData.append(
      "text_prompts[0][text]",
      `((vector illustration)), ((2d flat)),  new look, low details, ${title}`,
  );
  formData.append("text_prompts[0][weight]", 1);
  formData.append(
      "text_prompts[1][text]",
      "blurry, bad, watermark, artefacts, pastel, text, gun, logo",
  );
  formData.append("text_prompts[1][weight]", -1);

  const response = await fetch(
      "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/image-to-image",
      {
        method: "POST",
        headers: {
          ...formData.getHeaders(),
          Accept: "application/json",
          Authorization: `Bearer ${process.env.STABILITY_API_KEY}`,
        },
        body: formData,
      },
  );

  if (!response.ok) {
    throw new Error(`Non-200 response: ${await response.text()}`);
  }

  const responseJSON = await response.json();
  image = responseJSON.artifacts[0];
  console.log("received image", image.seed);
  return Buffer.from(image.base64, "base64");
}

exports.onSnapCreated = onDocumentCreated({
  secrets: ["STABILITY_API_KEY"],
  document: "snaps/{snapId}",

}, async (event) => {
  const snapshot = event.data;
  const data = snapshot.data();
  const bucket = getStorage().bucket();
  const file = bucket.file(data.fileRef);
  let image = await file.download();
  image = await transformImage(image[0], data.title);
  await file.save(image);
  const url = await getDownloadURL(file);
  // update processed
  return snapshot.ref.set(
      {
        processed: true,
        url: url,
      },
      {merge: true},
  );
});

// generate static page
// could be a spa with realtime data to firestore
exports.snap = onRequest(async (req, res) => {
  const snapshot = await getFirestore()
      .collection("snaps")
      .where("processed", "==", true)
      .orderBy("createdAt", "desc")
      .get();
  const posts = snapshot.docs.map(
      (doc) => `<div
  class="post"
  style="background-image:url('${doc.get("url")}')">
  <h2>${doc.get("title")}</h2></div>`,
  );
  res.send(`
    <!doctype html>
    <head>
      <title>Snap!</title>
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Anton&display=swap" rel="stylesheet">
      <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Anton', sans-serif;
        }
        h1 {
            color: #fff;
            background-color: #0d47a1;
            text-align: center;
            padding: 1rem;
            margin-top: 0;
        }
        .posts {
            margin: 1rem;  
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        }
        .post {
            background-size: cover;
            background-position: center;
            height: 300px;
            display: flex;
            flex-direction: column;
            justify-content: flex-end;
            padding: 1rem;
            color: white;
        }
      </style>
    </head>
    <body>
      <h1>Welcome to Snap!</h1>
        <div class="posts">
            ${posts.join("\n")}
        </div>
    </body>
  </html>`);
});
