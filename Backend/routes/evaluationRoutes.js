const express = require("express");
const router = express.Router();

router.post("/", async (req, res) => {

  console.log("Evaluación recibida:", req.body);

  res.json({
    message: "Evaluación guardada"
  });

});

module.exports = router;