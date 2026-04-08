const csvImportService = require("../services/csvImportService");

exports.importCSV = async (req, res) => {

  console.log("Ruta import-groups llamada");

  try {

    if (!req.file) {
      return res.status(400).json({
        error: "No se envió archivo"
      });
    }

    const filePath = req.file.path;

    await csvImportService.processCSV(filePath);

    res.json({
      message: "CSV procesado correctamente"
    });

  } catch (error) {

    console.error(error);

    res.status(500).json({
      error: "Error procesando CSV"
    });

  }

};