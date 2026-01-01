import consumer from "./consumer";

// Notification subscription for real-time updates
let notificationSubscription = null;

document.addEventListener("turbolinks:load", () => {
  // Initialize badge on page load
  updateMessagesBadge();

  // Clear unread count when Messages tab is clicked
  const messagesTabLink = document.getElementById("messages-tab-link");
  if (messagesTabLink) {
    // Remove existing listeners to avoid duplicates
    const newLink = messagesTabLink.cloneNode(true);
    messagesTabLink.parentNode.replaceChild(newLink, messagesTabLink);

    newLink.addEventListener("click", () => {
      clearUnreadMessageCount();
    });
  }

  // Also clear when already on Messages tab (page refresh)
  const currentTab = getCurrentTab();
  if (currentTab === "messages") {
    clearUnreadMessageCount();
  }

  // Create notification subscription
  notificationSubscription = consumer.subscriptions.create(
    { channel: "NotificationChannel" },
    {
      connected() {
        console.log("Notification subscription connected");
      },
      disconnected() {
        console.log("Notification subscription disconnected");
      },
      received(data) {
        console.log("Notification received:", data);

        // Show notification based on type
        if (data.type === "friend_request") {
          showFriendRequestNotification(data);
        } else if (data.type === "friend_request_accepted") {
          showFriendRequestAcceptedNotification(data);
        } else if (data.type === "new_message") {
          handleNewMessageNotification(data);
        }
      },
    }
  );
});

// Cleanup subscription on page unload
document.addEventListener("turbolinks:before-cache", () => {
  if (notificationSubscription) {
    notificationSubscription.unsubscribe();
    notificationSubscription = null;
  }
});

function showFriendRequestNotification(data) {
  // Find the chatroom header or create a container for flash messages
  const chatroomHeader = document.querySelector(
    ".ui.center.aligned.icon.header"
  );
  let flashContainer = document.querySelector(".flash-msg-container");

  if (!flashContainer && chatroomHeader) {
    flashContainer = document.createElement("div");
    flashContainer.className = "flash-msg-container";
    chatroomHeader.parentNode.insertBefore(
      flashContainer,
      chatroomHeader.nextSibling
    );
  } else if (!flashContainer) {
    flashContainer = createFlashContainer();
  }

  const flashMessage = document.createElement("div");
  flashMessage.className = "ui positive message flash-msg";
  flashMessage.style.marginTop = "10px";
  flashMessage.innerHTML = `
    <i class="close icon"></i>
    <div class="header">New Friend Request</div>
    <p>${data.message}</p>
    <a href="/chatroom?tab=friend_requests" class="ui small button">View Requests</a>
  `;

  flashContainer.appendChild(flashMessage);

  // Auto-dismiss after 8 seconds
  setTimeout(() => {
    if (flashMessage.parentNode) {
      flashMessage.remove();
    }
  }, 8000);

  // Close button functionality
  const closeBtn = flashMessage.querySelector(".close.icon");
  if (closeBtn) {
    closeBtn.addEventListener("click", () => {
      flashMessage.remove();
    });
  }

  // Update friend requests badge if on chatroom page
  updateFriendRequestsBadge();
}

function showFriendRequestAcceptedNotification(data) {
  const chatroomHeader = document.querySelector(
    ".ui.center.aligned.icon.header"
  );
  let flashContainer = document.querySelector(".flash-msg-container");

  if (!flashContainer && chatroomHeader) {
    flashContainer = document.createElement("div");
    flashContainer.className = "flash-msg-container";
    chatroomHeader.parentNode.insertBefore(
      flashContainer,
      chatroomHeader.nextSibling
    );
  } else if (!flashContainer) {
    flashContainer = createFlashContainer();
  }

  const flashMessage = document.createElement("div");
  flashMessage.className = "ui positive message flash-msg";
  flashMessage.style.marginTop = "10px";
  flashMessage.innerHTML = `
    <i class="close icon"></i>
    <div class="header">Friend Request Accepted</div>
    <p>${data.message}</p>
  `;

  flashContainer.appendChild(flashMessage);

  setTimeout(() => {
    if (flashMessage.parentNode) {
      flashMessage.remove();
    }
  }, 8000);

  const closeBtn = flashMessage.querySelector(".close.icon");
  if (closeBtn) {
    closeBtn.addEventListener("click", () => {
      flashMessage.remove();
    });
  }
}

function createFlashContainer() {
  const container = document.createElement("div");
  container.className = "flash-msg-container";
  document.body.insertBefore(container, document.body.firstChild);
  return container;
}

function updateFriendRequestsBadge() {
  // Reload the page to update the badge count, or make an AJAX call
  // For now, we'll just show the notification and let the user refresh
  // In a production app, you'd want to make an AJAX call to update the count
}

// Message notification handling
function handleNewMessageNotification(data) {
  // Check if user is currently on the Messages tab
  const currentTab = getCurrentTab();
  const isOnMessagesTab = currentTab === "messages";

  // Only increment unread count if NOT on Messages tab
  if (!isOnMessagesTab) {
    incrementUnreadMessageCount();
    updateMessagesBadge();
    showMessageNotification(data);
  }
}

function getCurrentTab() {
  const activeItem = document.querySelector(".ui.vertical.menu .item.active");
  if (activeItem) {
    const tabLink = activeItem.querySelector("a");
    if (tabLink) {
      const href = tabLink.getAttribute("href");
      const match = href.match(/[?&]tab=([^&]*)/);
      return match ? match[1] : null;
    }
  }
  return null;
}

function incrementUnreadMessageCount() {
  const currentCount = parseInt(
    localStorage.getItem("unread_message_count") || "0",
    10
  );
  localStorage.setItem("unread_message_count", (currentCount + 1).toString());
}

function getUnreadMessageCount() {
  return parseInt(localStorage.getItem("unread_message_count") || "0", 10);
}

function clearUnreadMessageCount() {
  localStorage.setItem("unread_message_count", "0");
  updateMessagesBadge();
}

function updateMessagesBadge() {
  const badge = document.getElementById("messages-unread-badge");
  if (!badge) return;

  const count = getUnreadMessageCount();
  if (count > 0) {
    badge.textContent = `+${count}`;
    badge.style.display = "inline-block";
  } else {
    badge.style.display = "none";
  }
}

function showMessageNotification(data) {
  const chatroomHeader = document.querySelector(
    ".ui.center.aligned.icon.header"
  );
  let flashContainer = document.querySelector(".flash-msg-container");

  if (!flashContainer && chatroomHeader) {
    flashContainer = document.createElement("div");
    flashContainer.className = "flash-msg-container";
    chatroomHeader.parentNode.insertBefore(
      flashContainer,
      chatroomHeader.nextSibling
    );
  } else if (!flashContainer) {
    flashContainer = createFlashContainer();
  }

  const messageType = data.message_type === "dm" ? "DM" : "Global Chat";
  const flashMessage = document.createElement("div");
  flashMessage.className = "ui blue message flash-msg";
  flashMessage.style.marginTop = "10px";
  flashMessage.innerHTML = `
    <i class="close icon"></i>
    <div class="header">New ${messageType} Message</div>
    <p><strong>${data.sender_username}:</strong> ${data.message_preview}</p>
    <a href="/chatroom?tab=messages" class="ui small button">View Messages</a>
  `;

  flashContainer.appendChild(flashMessage);

  setTimeout(() => {
    if (flashMessage.parentNode) {
      flashMessage.remove();
    }
  }, 8000);

  const closeBtn = flashMessage.querySelector(".close.icon");
  if (closeBtn) {
    closeBtn.addEventListener("click", () => {
      flashMessage.remove();
    });
  }
}
