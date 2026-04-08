const express = require("express");
const cors = require("cors");

const importRoutes = require("./routes/importRoutes");

const app = express();

const evaluationRoutes = require("./routes/evaluationRoutes");

app.use(cors());
app.use(express.json());

app.use("/api", importRoutes);

app.use("/api/evaluations", evaluationRoutes);

const PORT = 3000;

app.listen(PORT, () => {
  console.log("Servidor corriendo en puerto " + PORT);
});