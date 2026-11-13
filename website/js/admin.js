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
  const role = document.getElementById('new-user-role').value;
  if (!name) return alert('Enter a username');
  if (!role) return alert('Select a role');
  // First add the user
  callUserAPI('add', name).then(r => {
    if (r.error) { alert(r.error); return; }
    // Then add user to the role group
    callGroupAPIExtra('add_to_group', name, {group: role}).then(res => {
      alert(res.result || res.error);
      // Refresh both tables
      refreshUserList();
      refreshGroupList();
    });
  });
}
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

// Group related API calls
function callGroupAPI(action, name = "") {
  const params = new URLSearchParams({action, user: name});
  return fetch('/cgi-bin/manage_users.sh?' + params).then(r => r.json());
}

async function refreshGroupList() {
  const data = await callGroupAPI('group_list');
  const tbody = document.getElementById('group-table-body');
  tbody.innerHTML = '';
  const roleSelect = document.getElementById('new-user-role');
  if (roleSelect) roleSelect.innerHTML = '<option value="">Select role</option>';
  if (data.groups) {
    data.groups.forEach(g => {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${g}</td>
        <td><button onclick="deleteGroup('${g}')">Delete</button></td>
        <td><button onclick="showGroupMembers('${g}')">Members</button></td>`;
      tbody.appendChild(tr);
      if (roleSelect) {
        const opt = document.createElement('option');
        opt.value = g;
        opt.textContent = g;
        roleSelect.appendChild(opt);
      }
    });
  }
  const tbody = document.getElementById('group-table-body');
  tbody.innerHTML = '';
  if (data.groups) {
    data.groups.forEach(g => {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${g}</td>
        <td><button onclick="deleteGroup('${g}')">Delete</button></td>
        <td><button onclick="showGroupMembers('${g}')">Members</button></td>`;
      tbody.appendChild(tr);
    });
  }
}

function addGroup() {
  const name = document.getElementById('new-group-name').value.trim();
  if (!name) return alert('Enter a group name');
  callGroupAPI('group_add', name).then(r => {
    alert(r.result || r.error);
    refreshGroupList();
  });
}

function deleteGroup(name) {
  if (!confirm(`Delete group ${name}?`)) return;
  callGroupAPI('group_del', name).then(r => {
    alert(r.result || r.error);
    refreshGroupList();
  });
}

function showGroupMembers(group) {
  // Use the existing user "groups" action for each user – we just list users and filter client‑side
  callUserAPI('list').then(data => {
    const members = [];
    const promises = data.users.map(u => callUserAPI('groups', u));
    Promise.all(promises).then(results => {
      results.forEach((res, idx) => {
        if (res.info && res.info.includes(` ${group} `)) {
          members.push(data.users[idx]);
        }
      });
      alert(`Members of ${group}:\n` + (members.length ? members.join('\n') : '(none)'));
    });
  });
}

function addUserToGroup() {
  const user = document.getElementById('group-user-name').value.trim();
  const group = document.getElementById('group-name-select').value;
  if (!user || !group) return alert('Select both user and group');
  callGroupAPI('add_to_group', user, {group}).then(r => {
    // our generic callGroupAPI only passes action and user – we need a custom fetch for extra param
  });
}

// Because add_to_group and remove_from_group need an extra "group" parameter, we use a tiny helper
function callGroupAPIExtra(action, user, extra) {
  const params = new URLSearchParams({action, user, ...extra});
  return fetch('/cgi-bin/manage_users.sh?' + params).then(r => r.json());
}

function addUserToGroup() {
  const user = document.getElementById('group-user-name').value.trim();
  const group = document.getElementById('group-name-select').value;
  if (!user || !group) return alert('Select both user and group');
  callGroupAPIExtra('add_to_group', user, {group}).then(r => {
    alert(r.result || r.error);
  });
}

function removeUserFromGroup() {
  const user = document.getElementById('group-user-name').value.trim();
  const group = document.getElementById('group-name-select').value;
  if (!user || !group) return alert('Select both user and group');
  callGroupAPIExtra('remove_from_group', user, {group}).then(r => {
    alert(r.result || r.error);
  });
}

// Initialize both tables on load
document.addEventListener('DOMContentLoaded', () => {
  refreshUserList();
  refreshGroupList();
});


// expose for inline handlers
window.addUser = addUser;
window.deleteUser = deleteUser;
window.showGroups = showGroups;

