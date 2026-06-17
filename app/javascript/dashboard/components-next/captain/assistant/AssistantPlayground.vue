<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MessageList from './MessageList.vue';
import CaptainAssistant from 'dashboard/api/captain/assistant';

const { assistantId } = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const messages = ref([]);
const newMessage = ref('');
const isLoading = ref(false);

const formatMessagesForApi = () => {
  return messages.value.map(message => {
    const payload = {
      role: message.sender,
      content: message.content,
    };

    if (message.sender === 'assistant' && message.agentName) {
      payload.agent_name = message.agentName;
    }

    return payload;
  });
};

const resetConversation = () => {
  messages.value = [];
  newMessage.value = '';
};

// Watch for assistant ID changes and reset conversation
watch(
  () => assistantId,
  (newId, oldId) => {
    if (oldId && newId !== oldId) {
      resetConversation();
    }
  }
);

const formatErrorDetails = data => {
  const sections = [`**Error:** ${data.error_message || 'Unknown error'}`];

  if (data.response) {
    sections.push(`**Message:** ${data.response}`);
  }

  const debug = data.debug_info;
  if (debug) {
    const details = [
      `Request URL: ${debug.request_url || 'N/A'}`,
      `API base: ${debug.api_base || 'N/A'}`,
      `Provider: ${debug.provider || 'N/A'}`,
      `Model: ${debug.model || 'N/A'}`,
      `Response status: ${debug.response_status || 'N/A'}`,
    ].join('\n');
    sections.push(`**Debug Info:**\n${details}`);

    if (debug.response_body) {
      const body = typeof debug.response_body === 'string'
        ? debug.response_body
        : JSON.stringify(debug.response_body, null, 2);
      sections.push(`**Response Body:**\n${body}`);
    }
  }

  return sections.join('\n\n');
};

const sendMessage = async () => {
  if (!newMessage.value.trim() || isLoading.value) return;

  const messageHistory = formatMessagesForApi();
  const userMessage = {
    content: newMessage.value,
    sender: 'user',
    timestamp: new Date().toISOString(),
  };
  messages.value.push(userMessage);
  const currentMessage = newMessage.value;
  newMessage.value = '';

  try {
    isLoading.value = true;
    const { data } = await CaptainAssistant.playground({
      assistantId,
      messageContent: currentMessage,
      messageHistory,
    });

    if (data.error) {
      messages.value.push({
        content: formatErrorDetails(data),
        sender: 'assistant',
        timestamp: new Date().toISOString(),
        isError: true,
      });
    } else {
      messages.value.push({
        content: data.response,
        sender: 'assistant',
        agentName: data.agent_name,
        timestamp: new Date().toISOString(),
      });
    }
  } catch (error) {
    const errorMessage =
      error.response?.data?.error_message ||
      error.response?.data?.message ||
      error.message ||
      t('CAPTAIN.PLAYGROUND.ERROR_MESSAGE');
    messages.value.push({
      content: `❌ **Error:** ${errorMessage}`,
      sender: 'assistant',
      timestamp: new Date().toISOString(),
      isError: true,
    });
    // eslint-disable-next-line no-console
    console.error('Error getting assistant response:', error);
  } finally {
    isLoading.value = false;
  }
};

const handleEnterKey = event => {
  if (event.isComposing) return;
  event.preventDefault();
  sendMessage();
};
</script>

<template>
  <div
    class="flex flex-col h-full rounded-xl border py-6 border-n-weak text-n-slate-11"
  >
    <div class="mb-8 px-6">
      <div class="flex justify-between items-center mb-1">
        <h3 class="text-lg font-medium">
          {{ t('CAPTAIN.PLAYGROUND.HEADER') }}
        </h3>
        <NextButton
          ghost
          sm
          slate
          icon="i-lucide-rotate-ccw"
          @click="resetConversation"
        />
      </div>
      <p class="text-sm text-n-slate-11">
        {{ t('CAPTAIN.PLAYGROUND.DESCRIPTION') }}
      </p>
    </div>

    <MessageList :messages="messages" :is-loading="isLoading" />

    <div
      class="flex items-center mx-6 bg-n-background outline outline-1 outline-n-weak rounded-xl p-3"
    >
      <input
        v-model="newMessage"
        class="flex-1 bg-transparent border-none focus:outline-none text-sm mb-0 text-n-slate-12 placeholder:text-n-slate-10"
        :placeholder="t('CAPTAIN.PLAYGROUND.MESSAGE_PLACEHOLDER')"
        @keydown.enter.exact="handleEnterKey"
      />
      <NextButton
        ghost
        sm
        :disabled="!newMessage.trim()"
        icon="i-lucide-send"
        @click="sendMessage"
      />
    </div>

    <p class="text-xs text-n-slate-11 pt-2 text-center">
      {{ t('CAPTAIN.PLAYGROUND.CREDIT_NOTE') }}
    </p>
  </div>
</template>
