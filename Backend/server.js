const express = require("express");
const cors = require("cors");

const importRoutes = require("./routes/importRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api", importRoutes);

const PORT = 3000;

app.listen(PORT, () => {
  console.log("Servidor corriendo en puerto " + PORT);
});