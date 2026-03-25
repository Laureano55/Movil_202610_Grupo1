const express = require("express");
const multer = require("multer");
const importController = require("../controllers/importController");

const router = express.Router();

const upload = multer({
  dest: "uploads/"
});

router.post("/import-groups", upload.single("file"), importController.importCSV);

module.exports = router;