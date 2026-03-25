const students = [];

exports.findByEmail = (email) => {
  return students.find(student => student.email === email);
};

exports.createStudent = (student) => {
  students.push(student);
};

exports.updateStudent = (email, data) => {

  const student = students.find(s => s.email === email);

  if (student) {
    student.name = data.name;
    student.group = data.group;
  }

};

exports.getAllStudents = () => {
  return students;
};