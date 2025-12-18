import consumer from "./consumer";

// Helper: always keep scroll anchored to the latest messages
const scrollToBottom = (container) => {
  if (!container) return;
  container.scrollTop = container.scrollHeight;
};

// Global chat subscription
document.addEventListener("turbolinks:load", () => {
  const globalMessagesContainer = document.querySelector(
    "[data-global-messages]"
  );
  const globalForm = document.querySelector("[data-global-message-form]");
  const globalInput = document.querySelector("[data-global-message-input]");

  if (globalMessagesContainer) {
    // Inner feed container where individual message events live
    const globalFeed = globalMessagesContainer.querySelector(".ui.feed");

    const subscription = consumer.subscriptions.create(
      { channel: "ChatroomChannel" },
      {
        connected() {
          console.log("Global chat subscription connected");
        },
        disconnected() {
          console.log("Global chat subscription disconnected");
        },
        received(data) {
          // Append new message HTML into the feed so styling matches initially rendered messages
          const target = globalFeed || globalMessagesContainer;
          target.insertAdjacentHTML("beforeend", data.html);
          // Always scroll to the newest message on receive
          scrollToBottom(globalMessagesContainer);
        },
      }
    );

    // Cleanup subscription on page unload
    document.addEventListener("turbolinks:before-cache", () => {
      if (subscription) {
        subscription.unsubscribe();
      }
    });
  }

  if (globalForm && globalInput) {
    globalForm.addEventListener("ajax:success", () => {
      // Clear the input only; do not change scroll position
      globalInput.value = "";
      // Ensure sender also stays anchored to the newest message
      scrollToBottom(globalMessagesContainer);
    });
  }

  // When the page first loads, show the newest messages
  scrollToBottom(globalMessagesContainer);
});

// Conversation-specific subscription (DM)
let dmSubscription = null;

document.addEventListener("turbolinks:load", () => {
  const convoMessagesContainer = document.querySelector(
    "[data-conversation-messages]"
  );
  const convoElement = document.querySelector("[data-conversation-id]");
  const convoForm = document.querySelector("[data-conversation-message-form]");
  const convoInput = document.querySelector(
    "[data-conversation-message-input]"
  );

  if (convoMessagesContainer && convoElement) {
    const conversationIdStr = convoElement.getAttribute("data-conversation-id");
    const conversationId = parseInt(conversationIdStr, 10);

    if (isNaN(conversationId)) {
      console.error("Invalid conversation_id:", conversationIdStr);
      return;
    }

    // Unsubscribe from previous subscription if it exists
    if (dmSubscription) {
      dmSubscription.unsubscribe();
      dmSubscription = null;
    }

    // Inner feed container where individual message events live
    const convoFeed = convoMessagesContainer.querySelector(".ui.feed");

    dmSubscription = consumer.subscriptions.create(
      { channel: "ChatroomChannel", conversation_id: conversationId },
      {
        connected() {
          console.log(
            "DM subscription connected for conversation:",
            conversationId
          );
        },
        disconnected() {
          console.log(
            "DM subscription disconnected for conversation:",
            conversationId
          );
        },
        received(data) {
          console.log("DM message received:", data);
          // Append new message HTML into the feed so styling matches initially rendered messages
          const target = convoFeed || convoMessagesContainer;
          target.insertAdjacentHTML("beforeend", data.html);
          // Always scroll to the newest message on receive
          scrollToBottom(convoMessagesContainer);
        },
      }
    );
  }

  if (convoForm && convoInput) {
    convoForm.addEventListener("ajax:success", () => {
      // Clear the input only; do not change scroll position
      convoInput.value = "";
      // Ensure sender also stays anchored to the newest message
      scrollToBottom(convoMessagesContainer);
    });
  }

  // When the page first loads, show the newest messages
  if (convoMessagesContainer) {
    scrollToBottom(convoMessagesContainer);
  }
});

// Cleanup subscription on page unload
document.addEventListener("turbolinks:before-cache", () => {
  if (dmSubscription) {
    dmSubscription.unsubscribe();
    dmSubscription = null;
  }
});
