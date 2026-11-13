// admin.js – minimal front‑end for user management via CGI
// Uses the manage_users.sh CGI that returns JSON.

function callUserAPI(action, user = "") {
  const params = new URLSearchParams({action, user});
  return fetch('/cgi-bin/manage_users.sh?' + params)
    .then(r => r.json());
}

async function refreshUserList() {
  const data = await callUserAPI('list');
  const tbody = document.getElementById('user-table-body');
  tbody.innerHTML = '';
  if (data.users) {
    data.users.forEach(u => {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${u}</td>
        <td><button onclick="showGroups('${u}')">Groups</button></td>
        <td><button onclick="deleteUser('${u}')">Delete</button></td>`;
      tbody.appendChild(tr);
    });
  }
}

function addUser() {
  const name = document.getElementById('new-user-name').value.trim();
  if (!name) return alert('Enter a username');
  callUserAPI('add', name).then(r => {
    alert(r.result || r.error);
    refreshUserList();
  });
}

function deleteUser(name) {
  if (!confirm(`Delete user ${name}?`)) return;
  callUserAPI('del', name).then(r => {
    alert(r.result || r.error);
    refreshUserList();
  });
}

function showGroups(name) {
  callUserAPI('groups', name).then(r => {
    alert(r.info || r.error);
  });
}

document.addEventListener('DOMContentLoaded', refreshUserList);

// expose for inline handlers
window.addUser = addUser;
window.deleteUser = deleteUser;
window.showGroups = showGroups;

