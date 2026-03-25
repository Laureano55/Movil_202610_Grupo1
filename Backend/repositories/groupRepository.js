const groups = {};

exports.addStudentToGroup = (groupName, email) => {

  if (!groups[groupName]) {

    groups[groupName] = [];

  }

  if (!groups[groupName].includes(email)) {

    groups[groupName].push(email);

  }

};

exports.getGroups = () => groups;