const fs = require("fs");
const csv = require("csv-parser");

const groupRepository = require("../repositories/groupRepository");
const studentRepository = require("../repositories/studentRepository");

exports.processCSV = (filePath) => {

  return new Promise((resolve, reject) => {

    const students = [];

    fs.createReadStream(filePath)
      .pipe(csv())
      .on("data", (row) => {

        students.push(row);

      })
      .on("end", async () => {

        for (const student of students) {

          const email = student.email;
          const name = student.name;
          const group = student.group;

          const existingStudent = studentRepository.findByEmail(email);

          if (existingStudent) {

            studentRepository.updateStudent(email, {
              name,
              group
            });

          } else {

            studentRepository.createStudent({
              email,
              name,
              group
            });

          }

          groupRepository.addStudentToGroup(group, email);

        }

        resolve();

      })
      .on("error", reject);

  });

};