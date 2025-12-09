<template>
  <Notifications />
  <form :id="formId" @submit.prevent="submit">
    <div class="lg:flex lg:justify-center lg:content-center">
      <Input
        v-model="data.subject"
        class="mt-3 mr-2"
        id="input-subject"
        type="text"
        required
        label="Subject"
        :minlength="3"
      />
      <Input
        v-model="data.sender"
        class="mt-3"
        id="input-email"
        type="email"
        required
        label="Sender"
        :minlength="5"
      />
    </div>
    <Textarea
      v-model="data.message"
      class="mt-3"
      :rows="10"
      id="input-message"
      required
      label="Message"
      :minlength="10"
    />
    <Button v-if="canSubmit" type="submit">Submit</Button>
    <div id="turnstile-container"></div>
  </form>
</template>

<script lang="ts" setup>
import { reactive, ref } from "vue"
import Button from "./ui/Button.vue"
import Input from "./ui/Input.vue"
import Textarea from "./ui/Textarea.vue"
import { PUBLIC_DATEK_URL } from "@/utils/config"
import {
  notificationCollection,
  NotificationItem,
} from "./ui/notification/notification"
import Notifications from "./ui/notification/Notifications.vue"

const props = defineProps<{
  onTurnstileSuccess: string
  formId: string
  eventName: string
}>()

const canSubmit = ref(true)

type Data = {
  subject: string
  sender: string
  message: string
  token: string
}

const data = reactive<Data>(getInitialData())

function getInitialData(): Data {
  return {
    subject: "",
    sender: "",
    message: "",
    token: "",
  }
}

async function submit() {
  if (!canSubmit) return
  canSubmit.value = false

  // @ts-ignore
  turnstile.render("#turnstile-container", {
    sitekey: "0x4AAAAAACFAez1txbYrbLtj",
    callback: (token: string) => {
      data.token = token
      // @ts-ignore
      turnstile.remove("#turnstile-container")
      postForm()
    },
  })
}

async function postForm() {
  const response = await fetch(`${PUBLIC_DATEK_URL}/send-email/`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify(data),
  })

  if (response.status !== 200) {
    notificationCollection.addItem(
      new NotificationItem(
        "DANGER",
        "Something went wrong, couldn't send the email. Please try again later.",
        10,
      ),
    )
    canSubmit.value = true
    return
  }

  notificationCollection.addItem(
    new NotificationItem("INFO", "Email has been sent"),
  )

  for (const [key, value] of Object.entries(getInitialData())) {
    // @ts-ignore
    data[key] = value
  }

  canSubmit.value = true
}
</script>
